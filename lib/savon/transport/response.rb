# frozen_string_literal: true

require "httpi"
require "savon/transport/faraday"

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
      # Builds a Response from an HTTPI::Response.
      #
      # @param httpi_response [HTTPI::Response]
      # @return               [Transport::Response]
      def self.from_httpi(httpi_response)
        new(
          httpi_response.code,
          httpi_response.headers,
          httpi_response.body,
          cookies: ::HTTPI::Cookie.list_from_headers(httpi_response.headers)
        )
      end

      # Builds a Response from a Faraday::Response.
      #
      # @param faraday_response [Faraday::Response]
      # @return                 [Transport::Response]
      def self.from_faraday(faraday_response)
        new(
          faraday_response.status,
          faraday_response.headers.to_h,
          faraday_response.body,
          cookies: Savon::Transport::Faraday.parse_cookies(faraday_response.headers)
        )
      end

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
