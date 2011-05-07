require "httpi"

module Savon
  module WSDL

    # = Savon::WSDL::Request
    #
    # Executes WSDL requests.
    class Request

      # Expects an <tt>HTTPI::Request</tt> to execute a WSDL request
      # and returns the response.
      def self.execute(request)
        new(request).response
      end

      # Expects an <tt>HTTPI::Request</tt>.
      def initialize(request)
        self.request = request
      end

      # Accessor for the <tt>HTTPI::Request</tt>.
      attr_accessor :request

      # Executes the request and returns the response.
      def response
        @response ||= with_logging { HTTPI.get request }
      end

    private

      # Logs the HTTP request and yields to a given +block+.
      def with_logging
        Savon.log "----"
        Savon.log "WSDL request: #{request.url}"
        Savon.log "Using :#{request.auth.type} authentication" if request.auth?
        yield
      end

    end
  end
end
