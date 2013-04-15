require "httpi"

module Wasabi

  # = Wasabi::Resolver
  #
  # Resolves local and remote WSDL documents.
  class Resolver

    class HTTPError < StandardError
      def initialize(message, response=nil)
        super(message)
        @response = response
      end
      attr_reader :response
    end

    URL = /^http[s]?:/
    XML = /^</

    def initialize(document, request = nil)
      @document = document
      @request  = request || HTTPI::Request.new
    end

    attr_reader :document, :request

    def resolve
      raise ArgumentError, "Unable to resolve: #{document.inspect}" unless document

      case document
        when URL then load_from_remote
        when XML then document
        else          load_from_disc
      end
    end

    private

    def load_from_remote
      request.url = document
      response = HTTPI.get(request)

      raise HTTPError.new("Error: #{response.code}", response) if response.error?

      response.body
    end

    def load_from_disc
      File.read(document)
    end

  end
end
