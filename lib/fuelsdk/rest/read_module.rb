module FuelSDK
  module Rest
    module Read
    puts "Rest::Read was loaded!"
      def get
        client.rest_get id, properties
      end
    end
  end
end
