require "httpi"

module Wasabi

  # = Wasabi::Resolver
  #
  # Resolves local and remote WSDL documents.
  class Resolver

    class HTTPError < StandardError; end

    def initialize(document, request = nil)
      @document = document
      @request = request
    end

    def xml
      raise ArgumentError, "Wasabi is missing a document to resolve" unless @document

      case @document
        when /^http[s]?:/ then from_remote
        when /^</         then @document
        else                   from_fs
      end
    end

    private

    def from_remote
      response = HTTPI.get(request)
      raise HTTPError.new(response) if response.error?
      response.body
    end

    def request
      @request ||= HTTPI::Request.new
      @request.url = @document
      @request
    end

    def from_fs
      File.read(@document)
    end

  end
end
