class Savon
  class Resolver

    URL_PATTERN = /^http[s]?:/
    XML_PATTERN = /^</

    def initialize(http)
      @http = http
    end

    def resolve(location)
      case location
        when URL_PATTERN then @http.get(location)
        when XML_PATTERN then location
        else                  File.read(location)
      end
    end

  end
end
