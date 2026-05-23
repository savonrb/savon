# frozen_string_literal: true

require "httpi"
require "savon/transport/logging"
require "savon/transport/response"

module Savon
  module Transport
    # HTTPI-backed HTTP transport for the default HTTP path.
    #
    # Encapsulates everything HTTPI-specific:
    #   * header assembly
    #   * proxy/SSL/auth/timeout configuration
    #   * request execution
    class HTTPI
      include Logging

      # @param globals [Savon::GlobalOptions] the client-level options
      def initialize(globals)
        @globals = globals
      end

      # Assembles and executes a SOAP request, returning a Transport::Response.
      # Logs the outbound request and inbound response when logging is enabled.
      #
      # @param url          [String]              the SOAP endpoint URL
      # @param soap_headers [Hash]                SOAP-level headers
      # @param body         [String]              the serialized SOAP envelope
      # @param locals       [Savon::LocalOptions] per-request options
      # @return             [Transport::Response]
      def post(url, soap_headers, body, locals)
        http_request = to_httpi_request(url, soap_headers, body, locals)

        log_request(http_request.url, http_request.headers, http_request.body) if log?

        http_response = ::HTTPI.post(http_request, @globals[:adapter])
        response = Response.new(
          http_response.code,
          http_response.headers,
          http_response.body,
          cookies: ::HTTPI::Cookie.list_from_headers(http_response.headers)
        )

        log_response(response) if log?
        response
      end

      # Builds a fully-configured HTTPI::Request.
      #
      # @param url          [String]              the SOAP endpoint URL
      # @param soap_headers [Hash]                SOAP-level headers
      # @param body         [String]              the serialized SOAP envelope
      # @param locals       [Savon::LocalOptions] per-request options
      # @return             [HTTPI::Request]
      def to_httpi_request(url, soap_headers, body, locals)
        headers = {}
        headers.merge!(@globals[:headers]) if @globals.include?(:headers)
        headers.merge!(locals[:headers])   if locals.include?(:headers)

        # soap_headers are lowest priority
        soap_headers.each do |k, v| headers[k] ||= v end

        http_request = ::HTTPI::Request.new
        http_request.url = url
        http_request.body = body
        http_request.headers = headers
        http_request.set_cookies(locals[:cookies]) if locals[:cookies]
        configure_http_request(http_request)
        http_request
      end

      # Returns a configured HTTPI::Request for Wasabi's WSDL resolver.
      # Applies global headers and all transport-level options and
      # leaves the rest to Wasabi.
      #
      # @return [HTTPI::Request]
      def wsdl_request
        http_request = ::HTTPI::Request.new
        http_request.headers = @globals[:headers].dup if @globals.include?(:headers)
        configure_http_request(http_request)
        http_request
      end

      private

      def configure_http_request(http_request)
        configure_proxy(http_request)
        configure_timeouts(http_request)
        configure_ssl(http_request)
        configure_auth(http_request)
        configure_redirect_handling(http_request)
      end

      def configure_proxy(http_request)
        http_request.proxy = @globals[:proxy] if @globals.include?(:proxy)
      end

      def configure_timeouts(http_request)
        http_request.open_timeout  = @globals[:open_timeout]  if @globals.include?(:open_timeout)
        http_request.read_timeout  = @globals[:read_timeout]  if @globals.include?(:read_timeout)
        http_request.write_timeout = @globals[:write_timeout] if @globals.include?(:write_timeout)
      end

      # Configures SSL on the HTTPI::Request from all ssl globals.
      # SSL option reference: https://github.com/savonrb/httpi/blob/main/lib/httpi/auth/ssl.rb
      def configure_ssl(http_request)
        ssl = http_request.auth.ssl
        ssl.ssl_version       = @globals[:ssl_version]           if @globals.include?(:ssl_version)
        ssl.min_version       = @globals[:ssl_min_version]       if @globals.include?(:ssl_min_version)
        ssl.max_version       = @globals[:ssl_max_version]       if @globals.include?(:ssl_max_version)
        ssl.verify_mode       = @globals[:ssl_verify_mode]       if @globals.include?(:ssl_verify_mode)
        ssl.ciphers           = @globals[:ssl_ciphers]           if @globals.include?(:ssl_ciphers)
        ssl.cert_key_file     = @globals[:ssl_cert_key_file]     if @globals.include?(:ssl_cert_key_file)
        ssl.cert_key          = @globals[:ssl_cert_key]          if @globals.include?(:ssl_cert_key)
        ssl.cert_file         = @globals[:ssl_cert_file]         if @globals.include?(:ssl_cert_file)
        ssl.cert              = @globals[:ssl_cert]              if @globals.include?(:ssl_cert)
        ssl.ca_cert_file      = @globals[:ssl_ca_cert_file]      if @globals.include?(:ssl_ca_cert_file)
        ssl.ca_cert_path      = @globals[:ssl_ca_cert_path]      if @globals.include?(:ssl_ca_cert_path)
        ssl.ca_cert           = @globals[:ssl_ca_cert]           if @globals.include?(:ssl_ca_cert)
        ssl.cert_store        = @globals[:ssl_cert_store]        if @globals.include?(:ssl_cert_store)
        ssl.cert_key_password = @globals[:ssl_cert_key_password] if @globals.include?(:ssl_cert_key_password)
      end

      def configure_auth(http_request)
        http_request.auth.basic(*@globals[:basic_auth])   if @globals.include?(:basic_auth)
        http_request.auth.digest(*@globals[:digest_auth]) if @globals.include?(:digest_auth)
        http_request.auth.ntlm(*@globals[:ntlm])          if @globals.include?(:ntlm)
      end

      def configure_redirect_handling(http_request)
        http_request.follow_redirect = @globals[:follow_redirects] if @globals.include?(:follow_redirects)
      end
    end
  end
end
