require 'open-uri'
require 'net/https'
require 'json'

module FuelSDK
  module HTTPRequest

    # Returns a FuelSDL::HTTPResponse object
    request_methods = ['get', 'post', 'patch', 'delete']
    request_methods.each do |method|
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{method}(url, options={})                                      # def post(url, options)
          request Net::HTTP::#{method.capitalize}, url, options             #   request Net::HTTP::Post, url, options
        end                                                                 # end
      EOT
    end

    private

      def generate_uri(url, params=nil)
        uri = URI.parse(url)
        uri.query = URI.encode_www_form(params) if params
        uri
      end

      def request(method, url, options={})
        uri = generate_uri url, options['params']

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        data = options['data']
        _request = method.new uri.request_uri
        _request.body = data.to_json if data
        _request.content_type = options['content_type'] if options['content_type']
        response = http.request(_request)

        HTTPResponse.new(response, self, :url => url, :options => options)
      end

  end
end
