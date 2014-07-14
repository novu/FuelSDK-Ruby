require 'json'

module FuelSDK
  class HTTPResponse < FuelSDK::Response

    def initialize raw, client, request
      super raw, client
      @request = request
    end

    def continue
      rsp = nil

      if more?
       @request['options'][:page] = @results['page'].to_i + 1
       rsp = unpack @client.rest_get(@request['url'], @request['options'])
      end

      rsp
    end

    def [] key
      @results[key]
    end

    private
      def unpack raw
        @code    = raw.code.to_i
        @message = raw.message
        @body    = JSON.parse(raw.body) rescue {}
        @results = @body
        @more    = ((@results['count'] || @results['totalCount']) > @results['page'] * @results['pageSize']) rescue false
        @success = @message == 'OK'
      end

      # by default try everything against results
      def method_missing method, *args, &block
        @results.send(method, *args, &block)
      end
  end
end
