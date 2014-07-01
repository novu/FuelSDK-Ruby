module FuelSDK
  module Rest
    module CUD
    puts "Rest::CUD was loaded!"
      def post
        client.rest_post id, properties
      end

      def patch
        client.rest_patch id, properties
      end

      def delete
        client.rest_delete id, properties
      end
    end
  end
end
