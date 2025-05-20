# frozen_string_literal: true
require "faraday"

module Savon
  class HTTPRequest

    def initialize(globals, connection = nil)
      @globals = globals
      @connection = connection || Faraday::Connection.new
    end

    private

    def configure_proxy
      connection.proxy = @globals[:proxy] if @globals.include? :proxy
    end

    def configure_timeouts
      connection.options.open_timeout = @globals[:open_timeout] if @globals.include? :open_timeout
      connection.options.read_timeout = @globals[:read_timeout] if @globals.include? :read_timeout
      connection.options.write_timeout = @globals[:write_timeout] if @globals.include? :write_timeout
    end

    def configure_ssl
      connection.ssl.verify          = @globals[:ssl_verify]        if @globals.include? :ssl_verify
      connection.ssl.ca_file         = @globals[:ssl_ca_cert_file]  if @globals.include? :ssl_ca_cert_file
      connection.ssl.verify_hostname = @globals[:verify_hostname]   if @globals.include? :verify_hostname
      connection.ssl.ca_path         = @globals[:ssl_ca_cert_path]  if @globals.include? :ssl_ca_cert_path
      connection.ssl.verify_mode     = @globals[:ssl_verify_mode]   if @globals.include? :ssl_verify_mode
      connection.ssl.cert_store      = @globals[:ssl_cert_store]    if @globals.include? :ssl_cert_store
      connection.ssl.client_cert     = @globals[:ssl_cert]          if @globals.include? :ssl_cert
      connection.ssl.client_key      = @globals[:ssl_cert_key]      if @globals.include? :ssl_cert_key
      connection.ssl.certificate     = @globals[:ssl_certificate]   if @globals.include? :ssl_certificate
      connection.ssl.private_key     = @globals[:ssl_private_key]   if @globals.include? :ssl_private_key
      connection.ssl.verify_depth    = @globals[:verify_depth]      if @globals.include? :verify_depth
      connection.ssl.version         = @globals[:ssl_version]       if @globals.include? :ssl_version
      connection.ssl.min_version     = @globals[:ssl_min_version]   if @globals.include? :ssl_min_version
      connection.ssl.max_version     = @globals[:ssl_max_version]   if @globals.include? :ssl_max_version
      connection.ssl.ciphers         = @globals[:ssl_ciphers]       if @globals.include? :ssl_ciphers

      # No Faraday Equivalent out of box, see: https://lostisland.github.io/faraday/#/customization/ssl-options
      # connection.ssl.cert_file       = @globals[:ssl_cert_file]     if @globals.include? :ssl_cert_file
      # connection.ssl.cert_key_file   = @globals[:ssl_cert_key_file] if @globals.include? :ssl_cert_key_file
      # connection.ssl.ca_cert         = @globals[:ssl_ca_cert]       if @globals.include? :ssl_ca_cert
      # connection.ssl.cert_key_password = @globals[:ssl_cert_key_password] if @globals.include? :ssl_cert_key_password

    end

    def configure_auth
      basic_auth if @globals.include?(:basic_auth)
      ntlm_auth if @globals.include?(:ntlm)
    end

    def basic_auth
      connection.request(:authorization, :basic, *@globals[:basic_auth])
    end

    def ntlm_auth
      begin
        require 'rubyntlm'
        require 'faraday/net_http_persistent'
        connection.adapter :net_http_persistent, pool_size: 5
      rescue LoadError
        raise LoadError, 'Using NTLM Auth requires both `rubyntlm` and `faraday-net_http_persistent` to be installed.'
      end
    end

    def configure_redirect_handling
      if @globals[:follow_redirects]
        require 'faraday/follow_redirects'
        connection.response :follow_redirects
      end
    end

    def configure_adapter
      connection.adapter(*@globals[:adapter]) unless @globals[:adapter].nil?
    end

    def configure_logging
      connection.response(:logger, @globals[:logger], headers: @globals[:log_headers]) if @globals[:log]
    end

    def configure_gzip
      if connection.headers['Accept-Encoding'] && connection.headers['Accept-Encoding'].include?('gzip')
        connection.request :gzip
      end
    end

    protected
    attr_reader :connection
  end

  class WSDLRequest < HTTPRequest

    def build
      configure_proxy
      configure_timeouts
      configure_ssl
      configure_auth
      configure_adapter
      configure_logging
      configure_headers
      configure_gzip
      connection
    end

    private

    def configure_headers
      connection.headers = @globals[:headers] if @globals.include? :headers
    end
  end

  class SOAPRequest < HTTPRequest

    CONTENT_TYPE = {
      1 => "text/xml;charset=%s",
      2 => "application/soap+xml;charset=%s"
    }

    def build(options = {})
      configure_proxy
      configure_timeouts
      configure_ssl
      configure_auth
      configure_headers(options[:soap_action], options[:headers])
      configure_cookies(options[:cookies])
      configure_adapter
      configure_logging
      configure_redirect_handling
      configure_gzip
      yield(connection) if block_given?
      connection
    end

    private

    def configure_cookies(cookies)
      connection.headers['Cookie'] = cookies.map do |key, value|
        if value.nil?
          key
        else
          "#{key}=#{value}"
        end
      end.join('; ') if cookies
    end

    def configure_headers(soap_action, headers)
      connection.headers = @globals[:headers] if @globals.include? :headers
      connection.headers.merge!(headers) if headers
      connection.headers["SOAPAction"]   ||= %{"#{soap_action}"} if soap_action
      connection.headers["Content-Type"] ||= CONTENT_TYPE[@globals[:soap_version]] % @globals[:encoding]
    end
  end
end
