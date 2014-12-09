require 'securerandom'
module FuelSDK
  # http://help.exacttarget.com/en-US/technical_library/xml_api/xml_api_calls_and_sample_code/api_error_codes/error_code_numbers_and_descriptions/
	class Client
		attr_accessor :debug, :access_token, :internal_token, :refresh_token,
			:id, :secret, :signature, :package_name, :package_folders, :parent_folders,
			:auth_token, :auth_token_expiration
		attr_reader :api_auth_token_url

		include FuelSDK::Soap
		include FuelSDK::Rest


		def initialize(params={}, debug=false)
			self.debug  	= debug
			client_config = params[:client] || params['client']
			if client_config
				self.id 			 = client_config[:id]        || client_config['id']
				self.secret 	 = client_config[:secret]    || client_config['secret']
				self.signature = client_config[:signature] || client_config['signature']
 				@api_auth_token_url = client_config[:api_auth_token_url] || client_config['api_auth_token_url']
			end
			@api_auth_token_url ||= 'https://auth.exacttargetapis.com/v1/requestToken' # default production host
			# https://auth-test.exacttargetapis.com/v1/requestToken is used for the sandbox API

			self.jwt 					 = params[:jwt]           || params['jwt']
# See: https://code.exacttarget.com/apis-sdks/soap-api/using-the-api-key-to-authenticate-api-calls.html
			self.refresh_token = params[:refresh_token] || params['refresh_token']
			self.wsdl 				 = params[:defaultwsdl]   || params['defaultwsdl']
		end


		def jwt=(encoded_jwt)
			return if encoded_jwt.nil? or encoded_jwt.empty?
			raise 'Require app signature to decode JWT' unless self.signature
			decoded_jwt = JWT.decode(encoded_jwt, self.signature, true)['request']

			self.auth_token            = decoded_jwt['user']['oauthToken']
			self.internal_token        = decoded_jwt['user']['internalOauthToken']
			self.refresh_token         = decoded_jwt['user']['refreshToken']
			self.auth_token_expiration = Time.new + decoded_jwt['user']['expiresIn']
			self.package_name          = decoded_jwt['application']['package']
		end


		def refresh force=false
			raise 'Require Client Id and Client Secret to refresh tokens' unless (id && secret)
			#If we don't already have a token or the token expires within 5 min(300 seconds)
			if (force || self.access_token.nil? || Time.new + 300 > self.auth_token_expiration)
				payload = {
					clientId:     id,
					clientSecret: secret,
					accessType:   'offline'
				}
				payload[:refreshToken] = refresh_token if refresh_token

				options = {
					'data'         =>  payload,
					'content_type' => 'application/json',
					'params'       => {legacy: 1}
				}

				response = post(api_auth_token_url, refresh_options(payload))
				if response['message'] == 'Unauthorized' && payload[:refreshToken].present?
					old_token = payload.delete(:refreshToken)
					Rails.logger.info "[FuelSDK] Token refresh Unauthorized. Retrying after dumping old refreshToken: '#{old_token}'"
					response = post(api_auth_token_url, refresh_options(payload))
				end

				if response.has_key?('accessToken')
					Rails.logger.info "[FuelSDK] Auth Refresh Response Success: #{response}"
				else
					Rails.logger.error "[FuelSDK] Token refresh Failed. Response: #{response}"
					raise "Unable to refresh token: #{response['message']}"
				end

				self.access_token   			 = response['accessToken']
				self.internal_token 		   = response['legacyToken']
				self.auth_token_expiration = Time.new + response['expiresIn']
				self.refresh_token         = response['refreshToken'] if response.has_key?('refreshToken')
				true
			end
		end

		def refresh_options(payload)
			{
				'data'         =>  payload,
				'content_type' => 'application/json',
				'params'       => {legacy: 1}
			}
		end

		def refresh!
			refresh true
		end


		def AddSubscriberToList(email, ids, subscriber_key = nil)
			s = FuelSDK::Subscriber.new(self)
			lists = ids.collect{|id| {'ID' => id}}
			s.properties = {"EmailAddress" => email, "Lists" => lists}
			p s.properties
			s.properties['SubscriberKey'] = subscriber_key if subscriber_key

			# Try to add the subscriber
			if(rsp = s.post and rsp.results.first[:error_code] == '12014')
				# subscriber already exists we need to update.
				rsp = s.patch
			end
			rsp
		end


		def CreateDataExtensions(definitions)
			de = FuelSDK::DataExtension.new(self)
			de.properties = definitions
			de.post
		end


		def SendTriggeredSends(arrayOfTriggeredRecords)
			sendTS = FuelSDK::TriggeredSend.new(self)

			sendTS.properties = arrayOfTriggeredRecords
			sendResponse = sendTS.send

			return sendResponse
		end


		def SendEmailToList(emailID, listID, sendClassficationCustomerKey)
			email = FuelSDK::Email::SendDefinition.new(self)
			email.properties = {
				Name: SecureRandom.uuid,
				CustomerKey: SecureRandom.uuid,
				Description: 'Created with RubySDK',
				SendClassification: {CustomerKey: sendClassficationCustomerKey},
				SendDefinitionList: {List: {ID: listID}, "DataSourceTypeID"=>"List"},
				Email: {ID: emailID}
			}
			result = email.post

			if result.status
				sendresult = email.send
				if sendresult.status
					deleteresult = email.delete
					return sendresult
				else
					raise "Unable to send using send definition due to: #{result.results[0][:status_message]}"
				end
			else
				raise "Unable to create send definition due to: #{result.results[0][:status_message]}"
			end
		end


		def SendEmailToDataExtension(emailID, sendableDataExtensionCustomerKey, sendClassficationCustomerKey)
			email = FuelSDK::Email::SendDefinition.new(self)
			email.properties = {
				Name: SecureRandom.uuid,
				CustomerKey: SecureRandom.uuid,
				Description: 'Created with RubySDK',
				SendClassification: {CustomerKey: sendClassficationCustomerKey},
				SendDefinitionList: {CustomerKey: sendableDataExtensionCustomerKey, DataSourceTypeID: 'CustomObject'},
				Email: {ID: emailID}
			}
			result = email.post

			if result.status then
				sendresult = email.send
				if sendresult.status then
					deleteresult = email.delete
					return sendresult
				else
					raise "Unable to send using send definition due to: #{result.results[0][:status_message]}"
				end
			else
				raise "Unable to create send definition due to: #{result.results[0][:status_message]}"
			end
		end


		def CreateAndStartListImport(listId,fileName)
			import = FuelSDK::Import.new(self)
			import.properties = {"Name"=> "SDK Generated Import #{DateTime.now.to_s}"}
			import.properties["CustomerKey"] = SecureRandom.uuid
			import.properties["Description"] = "SDK Generated Import"
			import.properties["AllowErrors"] = "true"
			import.properties["DestinationObject"] = {"ID"=>listId}
			import.properties["FieldMappingType"] = "InferFromColumnHeadings"
			import.properties["FileSpec"] = fileName
			import.properties["FileType"] = "CSV"
			import.properties["RetrieveFileTransferLocation"] = {"CustomerKey"=>"ExactTarget Enhanced FTP"}
			import.properties["UpdateType"] = "AddAndUpdate"
			result = import.post

			if result.status then
				return import.start
			else
				raise "Unable to create import definition due to: #{result.results[0][:status_message]}"
			end
		end


		def CreateAndStartDataExtensionImport(dataExtensionCustomerKey, fileName, overwrite)
			import = FuelSDK::Import.new(self)
			import.properties = {"Name"=> "SDK Generated Import #{DateTime.now.to_s}"}
			import.properties["CustomerKey"] = SecureRandom.uuid
			import.properties["Description"] = "SDK Generated Import"
			import.properties["AllowErrors"] = "true"
			import.properties["DestinationObject"] = {"ObjectID"=>dataExtensionCustomerKey}
			import.properties["FieldMappingType"] = "InferFromColumnHeadings"
			import.properties["FileSpec"] = fileName
			import.properties["FileType"] = "CSV"
			import.properties["RetrieveFileTransferLocation"] = {"CustomerKey"=>"ExactTarget Enhanced FTP"}
			if overwrite
				import.properties["UpdateType"] = "Overwrite"
			else
				import.properties["UpdateType"] = "AddAndUpdate"
			end
			result = import.post

			if result.status
				import.start
			else
				raise "Unable to create import definition due to: #{result.results[0][:status_message]}"
			end
		end


		def CreateProfileAttributes(allAttributes)
			attrs = FuelSDK::ProfileAttribute.new(self)
			attrs.properties = allAttributes
			return attrs.post
		end


		def CreateContentAreas(arrayOfContentAreas)
			postC = FuelSDK::ContentArea.new(self)
			postC.properties = arrayOfContentAreas
			sendResponse = postC.post
			return sendResponse
		end
	end
end
