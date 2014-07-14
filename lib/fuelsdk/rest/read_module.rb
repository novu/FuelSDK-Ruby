module FuelSDK
  module Rest
    module Read
      def get
        client.rest_get id, properties
      end
    end
  end
end
