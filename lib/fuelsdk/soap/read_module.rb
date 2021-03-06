module FuelSDK
  module Soap
    module Read
      attr_accessor :filter

      def get(specified_id = id)
        client.soap_get specified_id, properties, filter
      end

      def info
        client.soap_describe id
      end
    end
  end
end
