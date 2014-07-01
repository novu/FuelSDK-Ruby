require 'savon'
module FuelSDK
  module Soap
    autoload :Response, 'fuelsdk/soap/response'
    autoload :DescribeResponse, 'fuelsdk/soap/describe_response'
    autoload :CUD, 'fuelsdk/soap/cud_module'
    autoload :Read, 'fuelsdk/soap/read_module'

    puts "Soap was loaded!"
    attr_accessor :wsdl, :debug#, :internal_token

    include FuelSDK::Targeting

    def header
      raise 'Require legacy token for soap header' unless internal_token
      {
        'oAuth' => {'oAuthToken' => internal_token},
        :attributes! => { 'oAuth' => { 'xmlns' => 'http://exacttarget.com' }}
      }
    end

    def debug
      @debug ||= false
    end

    def wsdl
      @wsdl ||= 'https://webservice.exacttarget.com/etframework.wsdl'
    end

    def soap_client
      self.refresh
      @soap_client = Savon.client(
        soap_header: header,
        wsdl: wsdl,
        endpoint: endpoint,
        wsse_auth: ["*", "*"],
        raise_errors: false,
        log: debug,
        open_timeout:180,
        read_timeout: 180,
        logger: Rails.logger,
        convert_request_keys_to: :camelcase,
        log: true
      )
    end

    def soap_describe object_type
      message = {
        'DescribeRequests' => {
          'ObjectDefinitionRequest' => {
            'ObjectType' => object_type
          }
        }
      }
      soap_request :describe, message
    end

    def soap_perform object_type, action, properties
      message = {}
      message['Action'] = action
      message['Definitions'] = {'Definition' => properties}
      message['Definitions'][:attributes!] = { 'Definition' => { 'xsi:type' => ('tns:' + object_type) }}

      soap_request :perform, message
    end


    def soap_configure  object_type, action, properties
     message = {}
     message['Action'] = action
     message['Configurations'] = {}

     message['Configurations']['Configuration'] = []
     properties.each do |configItem|
       message['Configurations']['Configuration'] << configItem
     end

     message['Configurations'][:attributes!] = { 'Configuration' => { 'xsi:type' => ('tns:' + object_type) }}

     soap_request :configure, message
    end

    def soap_get object_type, properties=nil, filter=nil
      if properties.nil? or properties.empty?
        puts '='*500
        puts "FuelSDL::Soap#soap_get: #{object_type}: properties.nil? or properties.empty?"
        rsp = soap_describe object_type
        puts
         rsp
        puts '='*500
        if rsp.success?
          properties = rsp.retrievable
        else
          rsp.instance_variable_set(:@message, "Unable to get #{object_type}") # back door update
          return rsp
        end
      elsif properties.kind_of? Hash
        properties = properties.keys
      elsif properties.kind_of? String
        properties = [properties]
      end

      message = {'ObjectType' => object_type, 'Properties' => properties}

      if filter and filter.kind_of? Hash
        puts '='*500
        puts "FuelSDL::Soap#soap_get - filter and filter.kind_of? Hash!"
        FuelSDK.schoff filter
        puts '='*500
        message['Filter'] = filter
        message[:attributes!] = { 'Filter' => { 'xsi:type' => 'tns:SimpleFilterPart' } }

        if filter.has_key?('LogicalOperator')
          message[:attributes!] = { 'Filter' => { 'xsi:type' => 'tns:ComplexFilterPart' }}
          message['Filter'][:attributes!] = {
            'LeftOperand' => { 'xsi:type' => 'tns:SimpleFilterPart' },
            'RightOperand' => { 'xsi:type' => 'tns:SimpleFilterPart' }}
        end
      end
      message = {'RetrieveRequest' => message}

        puts '='*500
        puts "FuelSDL::Soap#soap_get: soap_request(:retrieve, message) where message is:"
        FuelSDK.schoff message
        puts "Message"
        puts '='*500

      soap_request :retrieve, message
    end

    def soap_post object_type, properties
      soap_cud :create, object_type, properties
    end

    def soap_patch object_type, properties
      soap_cud :update, object_type, properties
    end

    def soap_delete object_type, properties
      soap_cud :delete, object_type, properties
    end

    private

      def soap_cud action, object_type, properties
puts  'C'*300
puts  "soap_cud #{action}, #{object_type},"
puts " #{properties}"
puts  '--'*30
=begin
        # get a list of attributes so we can seperate
        # them from standard object properties
        type_attrs = soap_describe(object_type).editable

=end
        properties = [properties] unless properties.kind_of? Array
=begin
        properties.each do |p|
          formated_attrs = []
          p.each do |k, v|
            if type_attrs.include? k
              p.delete k
              attrs = FuelSDK.format_name_value_pairs k => v
              formated_attrs.concat attrs
            end
          end
          (p['Attributes'] ||= []).concat formated_attrs unless formated_attrs.empty?
        end
=end

        # old: this format does not work
        message = {
          'Objects' => properties,
          :attributes! => { 'Objects' => { 'xsi:type' => ('tns:' + object_type) } }
        }
        # new: inlining like this seems to work better
        message = {
          'Objects' => {'@xsi:type' => "tns:#{object_type}", :content! => properties }
        }
puts  '--'*30
puts 'soap_request action, message'
puts  "action: #{action}\n message:"
        FuelSDK.schoff message
puts  'C'*300
        soap_request action, message
      end

      def soap_request action, message
        response = action.eql?(:describe) ? FuelSDK::Soap::DescribeResponse : FuelSDK::Soap::Response
        retried = false
        begin
          rsp = soap_client.call(action, message: message)
        rescue
          raise if retried
          retried = true
          retry
        end
        response.new rsp, self
      rescue
        raise if rsp.nil?
        response.new rsp, self
      end
  end
end
