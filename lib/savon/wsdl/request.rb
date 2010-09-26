require "httpi"
require "savon/logger"

module Savon
  module WSDL

    # = Savon::WSDL::Request
    #
    # Executes WSDL requests. Includes the <tt>Savon::Logger</tt> which allows you to specify
    # if and how WSDL requests should be logged.
    class Request
      include Logger

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
        log "Retrieving WSDL from: #{request.url}"
        log "Using :#{request.auth_type} authentication" if request.auth?
        yield
      end

    end
  end
end
