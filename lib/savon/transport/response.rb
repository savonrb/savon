# frozen_string_literal: true

module Savon
  module Transport
    # Transport-agnostic HTTP response value object.
    #
    # Every transport produces a Transport::Response so that higher-level code
    # never depends on transport-specific code. Immutable once constructed.
    class Response
      # Creates a Transport::Response from an HTTPI::Response.
      def self.from_httpi(httpi_response)
        new(httpi_response.code, httpi_response.headers, httpi_response.body)
      end

      # @param code    [Integer] HTTP status code
      # @param headers [Hash]    response headers
      # @param body    [String]  response body
      def initialize(code, headers, body)
        @code    = code
        @headers = headers
        @body    = body
      end

      # Returns the HTTP status code.
      attr_reader :code

      # Returns the response headers hash.
      attr_reader :headers

      # Returns the response body string.
      attr_reader :body

      # Returns true when the HTTP status code indicates an error (>= 300).
      def error?
        @code >= 300
      end
    end
  end
end
