#
# Contains object definitions for the following classes
#
# Campaign          < Objects::Base
#   Asset           < Objects::Base
# BounceEvent       < Objects::Base
# ClickEvent        < Objects::Base
# ContentArea       < Objects::Base
# DataFolder        < Objects::Base
# Email             < Objects::Base
#   SendDefinition  < Objects::Base
# Import            < Objects::Base
# List              < Objects::Base
#   Subscriber      < Objects::Base
# OpenEvent         < Objects::Base
# SentEvent         < Objects::Base
# Subscriber        < Objects::Base
# UnsubEvent        < Objects::Base
# ProfileAttribute  < Objects::Base
# TriggeredSend     < Objects::Base
# DataExtension     < Objects::Base
#   Column          < Objects::Base
#   Row             < Objects::Base
# Get               < Objects::Base
# Post              < Objects::Base
# Delete            < Objects::Base
# Patch             < Objects::Base



module FuelSDK


  #------------------------------------------------------------------------------------
  # Base class
  #------------------------------------------------------------------------------------

  module Objects
    class Base
      attr_accessor :properties, :client
      attr_reader :id

      def initialize(client=nil)
        self.client = client
      end

      alias props= properties= # backward compatibility
      alias authStub= client= # backward compatibility

      def properties
        if @properties.kind_of? Array
          @properties
        else
          [@properties].compact
        end
      end

      def id
        self.class.id
      end

      class << self
        def id
          self.name.split('::').last
        end
      end
    end
  end


  #------------------------------------------------------------------------------------
  # REST objects
  #------------------------------------------------------------------------------------


  class Campaign < Objects::Base
    include FuelSDK::Rest::Read
    include FuelSDK::Rest::CUD

    def properties
      @properties ||= {}
      @properties['id'] ||= ''
      @properties
    end

    def id
      "https://www.exacttargetapis.com/hub/v1/campaigns/%{id}"
    end

    class Asset < Objects::Base
      include FuelSDK::Rest::Read
      include FuelSDK::Rest::CUD

      def properties
        @properties ||= {}
        @properties['assetId'] ||= ''
        @properties
      end

      def id
        'https://www.exacttargetapis.com/hub/v1/campaigns/%{id}/assets/%{assetId}'
      end
    end
  end


  #------------------------------------------------------------------------------------
  # SOAP objects
  #------------------------------------------------------------------------------------


  class BounceEvent < Objects::Base
	  attr_accessor :get_since_last_batch
    include FuelSDK::Soap::Read
  end


  class ClickEvent < Objects::Base
	  attr_accessor :get_since_last_batch
    include FuelSDK::Soap::Read
  end


  class ContentArea < Objects::Base
    include FuelSDK::Soap::Read
    include FuelSDK::Soap::CUD
  	attr_accessor :folder_id

    def folder_property
      'CategoryID'
    end

    def folder_media_type
      'content'
    end
  end


  class DataFolder < Objects::Base
    include FuelSDK::Soap::Read
    include FuelSDK::Soap::CUD
  end


  class Folder < DataFolder
    class << self
      def id
        DataFolder.id
      end
    end
  end


  class Email < Objects::Base
    include FuelSDK::Soap::Read
    include FuelSDK::Soap::CUD
  	attr_accessor :folder_id

  	def folder_property
  		'CategoryID'
  	end

  	def folder_media_type
  		'email'
  	end

    class SendDefinition < Objects::Base
      include FuelSDK::Soap::Read
      include FuelSDK::Soap::CUD
	    attr_accessor :folder_id

      def id
        'EmailSendDefinition'
      end

      def folder_property
        'CategoryID'
      end

      def folder_media_type
        'userinitiatedsends'
      end

      def send
        perform_response = client.soap_perform id, 'start' , properties
        if perform_response.status then
          @last_task_id = perform_response.results[0][:result][:task][:id]
        end
        perform_response
      end

      def status
        client.soap_get 'Send', ['ID','CreatedDate', 'ModifiedDate', 'Client.ID', 'Email.ID', 'SendDate','FromAddress','FromName','Duplicates','InvalidAddresses','ExistingUndeliverables','ExistingUnsubscribes','HardBounces','SoftBounces','OtherBounces','ForwardedEmails','UniqueClicks','UniqueOpens','NumberSent','NumberDelivered','NumberTargeted','NumberErrored','NumberExcluded','Unsubscribes','MissingAddresses','Subject','PreviewURL','SentDate','EmailName','Status','IsMultipart','SendLimit','SendWindowOpen','SendWindowClose','BCCEmail','EmailSendDefinition.ObjectID','EmailSendDefinition.CustomerKey'], {'Property' => 'ID','SimpleOperator' => 'equals','Value' => @last_task_id}
      end

      private
      attr_accessor :last_task_id

    end
  end


  class Import < Objects::Base
    include FuelSDK::Soap::Read
    include FuelSDK::Soap::CUD

    def id
      'ImportDefinition'
    end

    def post
      originalProp = properties
      cleanProps
      obj = super
      properties = originalProp
      return obj
    end

    def patch
      originalProp = properties
      cleanProps
      obj = super
      properties = originalProp
      return obj
    end

    def start
      perform_response = client.soap_perform id, 'start' , properties
      if perform_response.status then
        @last_task_id = perform_response.results[0][:result][:task][:id]
      end
      perform_response
    end

    def status
      client.soap_get 'ImportResultsSummary', ['ImportDefinitionCustomerKey','TaskResultID','ImportStatus','StartDate','EndDate','DestinationID','NumberSuccessful','NumberDuplicated','NumberErrors','TotalRows','ImportType'], {'Property' => 'TaskResultID','SimpleOperator' => 'equals','Value' => @last_task_id}
    end

    private

    attr_accessor :last_task_id

    def cleanProps
      # If the ID property is specified for the destination then it must be a list import
      if properties.has_key?('DestinationObject') then
        if properties['DestinationObject'].has_key?('ID') then
          properties[:attributes!] = { 'DestinationObject' => { 'xsi:type' => 'tns:List'}}
        end
      end
    end
  end


  class List < Objects::Base
    include FuelSDK::Soap::Read
    include FuelSDK::Soap::CUD
    attr_accessor :folder_id

  	def folder_property
  		'Category'
  	end

  	def folder_media_type
  		'list'
  	end

    class Subscriber < Objects::Base
      include FuelSDK::Soap::Read
      def id
        'ListSubscriber'
      end
    end
  end


  class OpenEvent < Objects::Base
  	attr_accessor :get_since_last_batch
    include FuelSDK::Soap::Read
  end


  class SentEvent < Objects::Base
	  attr_accessor :get_since_last_batch
    include FuelSDK::Soap::Read
  end


  class Subscriber < Objects::Base
    include FuelSDK::Soap::Read
    include FuelSDK::Soap::CUD
  end


  class UnsubEvent < Objects::Base
  	attr_accessor :get_since_last_batch
    include FuelSDK::Soap::Read
  end


  class ProfileAttribute < Objects::Base
    def get
      client.soap_describe 'Subscriber'
    end

    def post
      client.soap_configure 'PropertyDefinition','create', properties
    end

    def delete
      client.soap_configure 'PropertyDefinition','delete', properties
    end

    def patch
      client.soap_configure 'PropertyDefinition','update', properties
    end
  end


  class TriggeredSend < Objects::Base
    include FuelSDK::Soap::Read
    include FuelSDK::Soap::CUD
  	attr_accessor :folder_id, :subscribers

    def id
      'TriggeredSendDefinition'
    end

    def folder_property
      'CategoryID'
    end

    def folder_media_type
      'triggered_send'
    end

    def send
      if self.properties.is_a? Array then
        tscall = []
        self.properties.each{ |p|
          tscall.push({'TriggeredSendDefinition' => {'CustomerKey' => p['CustomerKey']}, 'Subscribers' => p['Subscribers']})
        }
      else
        tscall = {'TriggeredSendDefinition' => self.properties, 'Subscribers' => @subscribers}
      end
      client.soap_post 'TriggeredSend', tscall
    end
  end


  class DataExtension < Objects::Base
    include FuelSDK::Soap::Read
    include FuelSDK::Soap::CUD
    attr_accessor :fields, :folder_id

  	def folder_property
  	  'CategoryID'
  	end

  	def folder_media_type
  	  'dataextension'
  	end

    alias columns= fields= # backward compatibility

    def post
      munge_fields self.properties
      super
    end

    def patch
      munge_fields self.properties
      super
    end


    class Column < Objects::Base
      include FuelSDK::Soap::Read

      def id
        'DataExtensionField'
      end

      def get
        if filter.kind_of? Hash
          # %% filter.include? 'Property' and filter['Property'] == 'CustomerKey'
          if property_key = filter.keys.detect{|p| p.to_s.downcase == 'property' }
            if filter[property_key].to_s.downcase == 'customerkey'
              filter[property_key] = 'DataExtension.CustomerKey'
            end
          end
        end

        #   ['Property']||filter['Property']
        #   filter.include? 'Property' and filter['Property'] == 'CustomerKey'
        #   filter['Property'] = 'DataExtension.CustomerKey'
        # end
        super
      end
    end


    class Row < Objects::Base
      include FuelSDK::Soap::Read
      include FuelSDK::Soap::CUD

      attr_accessor :name, :customer_key

      # backward compatibility
      alias Name= name=
      alias CustomerKey= customer_key=

      def id
        'DataExtensionObject'
      end

      def get
        super "#{id}[#{name}]"
      end

      def name
        @name ||= lookup_name_using_customer_key
      end

      def customer_key
        @customer_key ||= lookup_customer_key_using_name
      end

      def post
        self.properties = munge_properties
        super
      end

      def patch
        self.properties = munge_properties
        super
      end

      def delete
        self.properties = munge_keys
        super
      end

      # private

      #::TODO::
      # opportunity for meta programming here... but need to get this out the door
      def munge_keys(target=nil)
        target ||= self.properties
  			if target.kind_of? Array

          target.map do |hash|
            if hash['CustomerKey'] && hash['Keys'] && hash['Keys']['Key']
              hash # looks good. Keep it
            else
              munge_keys(hash)
            end
          end

  			else
          clean_props = hash_without_customer_key(target)
          {
            'CustomerKey' => customer_key,
  				  'Keys' => {'Key' => FuelSDK.format_props(clean_props) }
          }
  			end
      end

      def munge_properties(target=nil)
        target ||= self.properties
  			if target.kind_of? Array
  			  target.map do |hash|
  				  if has_property_key_already(hash) && hash['CustomerKey']
              hash # looks good. Keep it
            else
              munge_properties(hash)
            end
          end
  			else
          clean_props = hash_without_customer_key(target)
          {
            'CustomerKey' => customer_key,
            'Properties' => {'Property' => FuelSDK.format_props(clean_props) }
          }
  			end
      end

      def has_property_key_already h
        h['Properties'] and h['Properties']['Property']
      end

      def hash_without_customer_key(hash)
        if hash['CustomerKey']
          hash = hash.dup
          hash.delete('CustomerKey')
        end
        hash
      end

      def lookup_name_using_customer_key
        return @name if @name
        raise_missing_properties_error if @customer_key.nil?
        filter = property_equals_filter('CustomerKey', @customer_key)
        assign_required_properties(filter)
        self.name
      end

      def lookup_customer_key_using_name
        return @customer_key if @customer_key
        raise_missing_properties_error if @name.nil?
        filter = property_equals_filter('Name', @name)
        assign_required_properties(filter)
        self.customer_key
      end

      def raise_missing_properties_error
        raise 'Unable to process DataExtension::Row ' \
            'request due to missing both CustomerKey and Name'
      end

      def property_equals_filter(key, value)
        {
          'Property' => key,
          'SimpleOperator' => 'equals',
          'Value' => value
        }
      end

      def assign_required_properties(filter)
        rsp = client.soap_get 'DataExtension', ['Name', 'CustomerKey'], filter
        if rsp.success? && rsp.results.count == 1
          self.name = rsp.results.first[:name]
          self.customer_key = rsp.results.first[:customer_key]
        else
          raise 'Unable to process DataExtension::Row'
        end
      end

      def require_name_and_customer_key
        # have to use instance variables so we don't recursivelly require_name_and_customer_key
        if !@name && !@customer_key
          raise 'Unable to process DataExtension::Row ' \
            'request due to missing both CustomerKey and Name'
        end
        if !@name || !@customer_key
          filter = {
            'Property' => @name.nil? ? 'CustomerKey' : 'Name',
            'SimpleOperator' => 'equals',
            'Value' => @customer_key || @name
          }
          rsp = client.soap_get 'DataExtension', ['Name', 'CustomerKey'], filter
          if rsp.success? && rsp.results.count == 1
            self.name = rsp.results.first[:name]
            self.customer_key = rsp.results.first[:customer_key]
          else
            raise 'Unable to process DataExtension::Row'
          end
        end
      end
    end

    private

    def munge_fields d
		  # maybe one day will make it smart enough to zip properties and fields if count is same?
		  if d.kind_of? Array and d.count > 1 and (fields and !fields.empty?)
			  # we could map the field to all DataExtensions, but lets make user be explicit.
			  # if they are going to use fields attribute properties should
			  # be a single DataExtension Defined in a Hash
			  raise 'Unable to handle muliple DataExtension definitions and a field definition'
		  end

		  d.each do |de|

			  if (explicit_fields(de) and (de['columns'] || de['fields'] || has_fields)) or
				  (de['columns'] and (de['fields'] || has_fields)) or
				  (de['fields'] and has_fields)
				  raise 'Fields are defined in too many ways. Please only define once.' # ahhh what, to do...
			  end

			  # let users who chose, to define fields explicitly within the hash definition
			  next if explicit_fields de

			  de['Fields'] = {'Field' => de['columns'] || de['fields'] || fields}
			  # sanitize
			  de.delete 'columns'
			  de.delete 'fields'
			  raise 'DataExtension needs atleast one field.' unless de['Fields']['Field']
		  end
    end

    def explicit_fields h
      h['Fields'] and h['Fields']['Field']
    end

    def has_fields
      fields and !fields.empty?
    end
  end


  # Direct Verb Access Section


  class Get < Objects::Base
    include FuelSDK::Soap::Read
    attr_accessor :id

    def initialize client, id, properties, filter
      self.properties = properties
      self.filter = filter
      self.client = client
      self.id = id
    end

    def get
      super id
    end

    class << self
      def new client, id, properties=nil, filter=nil
        o = self.allocate
        o.send :initialize, client, id, properties, filter
        return o.get
      end
    end
  end


  class Post < Objects::Base
    include FuelSDK::Soap::CUD
    attr_accessor :id

    def initialize client, id, properties
      self.properties = properties
      self.client = client
      self.id = id
    end

    def post
      super
    end

    class << self
      def new client, id, properties=nil
        o = self.allocate
        o.send :initialize, client, id, properties
        return o.post
      end
    end
  end


  class Delete < Objects::Base
    include FuelSDK::Soap::CUD
    attr_accessor :id

    def initialize client, id, properties
      self.properties = properties
      self.client = client
      self.id = id
    end

    def delete
      super
    end

    class << self
      def new client, id, properties=nil
        o = self.allocate
        o.send :initialize, client, id, properties
        return o.delete
      end
    end
  end


  class Patch < Objects::Base
    include FuelSDK::Soap::CUD
    attr_accessor :id

    def initialize client, id, properties
      self.properties = properties
      self.client = client
      self.id = id
    end

    def patch
      super
    end

    class << self
      def new client, id, properties=nil
        o = self.allocate
        o.send :initialize, client, id, properties
        return o.patch
      end
    end
  end

end
