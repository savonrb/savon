# frozen_string_literal: true

require "savon/transport/logging"
require "savon/transport/response"

module Savon
  module Transport
    # Faraday-backed HTTP transport for the opt-in Faraday path.
    #
    # Encapsulates everything Faraday-specific:
    #   * header assembly (SOAP + global + local + cookies)
    #   * request execution via the caller-configured Faraday::Connection
    #
    # Transport-level concerns (SSL, auth, proxy, timeouts, middleware) are
    # the caller's responsibility via client.faraday before any call is made.
    class Faraday
      include Logging

      # @param connection [Faraday::Connection] the memoized connection from client.faraday
      # @param globals    [Savon::GlobalOptions] the client-level options
      def initialize(connection, globals)
        @connection = connection
        @globals    = globals
      end

      # Assembles headers, executes the POST via the Faraday connection, and
      # returns a Transport::Response. Logs the outbound request and inbound
      # response when logging is enabled.
      #
      # @param url          [String]              the SOAP endpoint URL
      # @param soap_headers [Hash]                SOAP-level headers (Content-Type, SOAPAction, etc.)
      # @param body         [String]              the serialized SOAP envelope
      # @param locals       [Savon::LocalOptions] per-request options
      # @return             [Transport::Response]
      def post(url, soap_headers, body, locals)
        headers = build_headers(soap_headers, locals)

        log_request(url, headers, body) if log?

        faraday_response = @connection.post(url, body, headers)
        response = Response.new(
          faraday_response.status,
          faraday_response.headers.to_h,
          faraday_response.body,
          cookies: self.class.parse_cookies(faraday_response.headers)
        )

        log_response(response) if log?
        response
      end

      # Parses Set-Cookie headers into a Hash of name => value. Accepts both
      # the Array and String form. Attributes after the first ';' are discarded.
      def self.parse_cookies(headers)
        raw = headers["set-cookie"] || headers["Set-Cookie"]
        return {} unless raw

        raw_array = raw.is_a?(Array) ? raw : raw.split(/,\s*/)
        raw_array.each_with_object({}) do |cookie_str, hash|
          name_value = cookie_str.split(";", 2).first.to_s.strip
          name, value = name_value.split("=", 2)
          hash[name] = value if name && !name.empty?
        end
      end

      private

      # Merges all header sources in precedence order:
      # locals[:headers] > globals[:headers] > soap_headers
      # Appends Cookie from locals[:cookies].
      def build_headers(soap_headers, locals)
        headers = {}
        headers.merge!(@globals[:headers]) if @globals.include?(:headers)
        headers.merge!(locals[:headers])   if locals.include?(:headers)

        # soap_headers are lowest priority
        soap_headers.each do |k, v| headers[k] ||= v end

        cookie_header = format_cookies(locals[:cookies])
        headers["Cookie"] = cookie_header if cookie_header

        headers
      end

      # Builds the Cookie header from a given value.
      # Accepts:
      #   * String - passed through verbatim
      #   * Hash   - formatted as "name=value; name=value" (browser style)
      # Returns nil when no cookies were supplied.
      def format_cookies(cookies)
        return nil if cookies.nil?
        return cookies if cookies.is_a?(String)

        cookies.map { |name, value| "#{name}=#{value}" }.join("; ")
      end
    end
  end
end
