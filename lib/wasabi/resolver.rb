require 'httpi'

class Wasabi
  class Resolver

    URL_PATTERN = /^http[s]?:/
    XML_PATTERN = /^</

    def initialize(request = nil)
      @request = request || HTTPI::Request.new
    end

    def resolve(location)
      case location
        when URL_PATTERN then load_from_remote(location)
        when XML_PATTERN then location
        else                  load_from_disc(location)
      end
    end

    private

    def load_from_remote(location)
      @request.url = location
      response = HTTPI.get(@request)

      raise HTTPError.new("Error: #{response.code}", response) if response.error?

      response.body
    end

    def load_from_disc(location)
      File.read(location)
    end

  end
end
