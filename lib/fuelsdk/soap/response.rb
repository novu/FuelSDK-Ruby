module FuelSDK
  module Soap
    puts "Response was loaded!"
    class Response < FuelSDK::Response

      def continue
        rsp = nil
        if more?
         rsp = unpack @client.soap_client.call(:retrieve, :message => {'ContinueRequest' => request_id})
        else
          puts 'No more data'
        end

        rsp
      end

      private

      def unpack_body raw
        @body = raw.body
        @request_id = raw.body[raw.body.keys.first][:request_id]
        unpack_msg raw
      rescue
        @message = raw.http.body
        @body = raw.http.body unless @body
      end

      def unpack raw
        @code = raw.http.code
        unpack_body raw
        @success = @message == 'OK'
        @results += (unpack_rslts raw)
      end

      def unpack_msg raw
        @message = raw.soap_fault? ? raw.body[:fault][:faultstring] : raw.body[raw.body.keys.first][:overall_status]
      end

      def unpack_rslts raw
        @more = (raw.body[raw.body.keys.first][:overall_status] == 'MoreDataAvailable')
        rslts = raw.body[raw.body.keys.first][:results] || []
        rslts = [rslts] unless rslts.kind_of? Array
        rslts
      rescue
        []
      end
    end
  end
end

