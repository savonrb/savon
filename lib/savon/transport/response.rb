# frozen_string_literal: true

module Savon
  module Transport
    # Transport-agnostic HTTP response value object.
    #
    # Every transport produces a Transport::Response so that higher-level code
    # never depends on transport-specific code. Immutable once constructed.
    #
    # The shape of #cookies is transport-specific: HTTPI responses expose an
    # Array of HTTPI::Cookie, while Faraday responses expose a plain Hash so
    # Faraday users do not depend on HTTPI types.
    class Response
      # @param code    [Integer] HTTP status code
      # @param headers [Hash]    response headers
      # @param body    [String]  response body
      # @param cookies [Object]  parsed cookies in a transport-specific shape
      def initialize(code, headers, body, cookies: nil)
        @code    = code
        @headers = headers
        @body    = body
        @cookies = cookies
      end

      # Returns the HTTP status code.
      attr_reader :code

      # Returns the response headers hash.
      attr_reader :headers

      # Returns the response body string.
      attr_reader :body

      # Returns the parsed cookies in a transport-specific shape.
      # See class-level docs.
      attr_reader :cookies

      # Returns true when the HTTP status code indicates an error (>= 300).
      def error?
        @code >= 300
      end
    end
  end
end
