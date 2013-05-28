require 'httpi'

class Wasabi
  class Resolver

    URL = /^http[s]?:/
    XML = /^</

    def initialize(request = nil)
      @request = request || HTTPI::Request.new
    end

    def resolve(location)
      case location
        when URL then load_from_remote(location)
        when XML then location
        else          load_from_disc(location)
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
