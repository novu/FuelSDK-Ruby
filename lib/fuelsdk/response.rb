module FuelSDK
  class Response
    # not doing accessor so user, can't update these values from response.
    # You will see in the code some of these
    # items are being updated via back doors and such.
    attr_reader :code, :message, :results, :request_id, :body, :raw


    def initialize raw, client
      @client = client # keep connection with client in case we request more
      @results = []
      @raw = raw
      unpack raw
    rescue => ex # all else fails return raw
      puts ex.message
      raw
    end


    # some defaults
    def success
      @success ||= false
    end
    alias :success? :success
    alias :status :success # backward compatibility

    def more
      @more ||= false
    end
    alias :more? :more

    def continue
      raise NotImplementedError
    end

    private

    def unpack raw
      raise NotImplementedError
    end
  end



end
