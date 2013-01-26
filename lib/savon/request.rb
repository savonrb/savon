require "httpi"

module Savon
  class HTTPRequest

    def initialize(globals, http_request = nil)
      @globals = globals
      @http_request = http_request || HTTPI::Request.new
    end

    def build
      @http_request
    end

    private

    def configure_proxy
      @http_request.proxy = @globals[:proxy] if @globals.include? :proxy
    end

    def configure_timeouts
      @http_request.open_timeout = @globals[:open_timeout] if @globals.include? :open_timeout
      @http_request.read_timeout = @globals[:read_timeout] if @globals.include? :read_timeout
    end

    def configure_ssl
      @http_request.auth.ssl.ssl_version   = @globals[:ssl_version]       if @globals.include? :ssl_version
      @http_request.auth.ssl.verify_mode   = @globals[:ssl_verify_mode]   if @globals.include? :ssl_verify_mode

      @http_request.auth.ssl.cert_key_file = @globals[:ssl_cert_key_file] if @globals.include? :ssl_cert_key_file
      @http_request.auth.ssl.cert_file     = @globals[:ssl_cert_file]     if @globals.include? :ssl_cert_file
      @http_request.auth.ssl.ca_cert_file  = @globals[:ssl_ca_cert_file]  if @globals.include? :ssl_ca_cert_file

      @http_request.auth.ssl.cert_key_password = @globals[:ssl_cert_key_password] if @globals.include? :ssl_cert_key_password
    end

    def configure_auth
      @http_request.auth.basic(*@globals[:basic_auth])   if @globals.include? :basic_auth
      @http_request.auth.digest(*@globals[:digest_auth]) if @globals.include? :digest_auth
    end

  end

  class WSDLRequest < HTTPRequest

    def build
      configure_proxy
      configure_timeouts
      configure_ssl
      configure_auth

      @http_request
    end

  end

  class SOAPRequest < HTTPRequest

    CONTENT_TYPE = {
      1 => "text/xml;charset=%s",
      2 => "application/soap+xml;charset=%s"
    }

    def build(options = {})
      configure_proxy
      configure_cookies options[:cookies]
      configure_timeouts
      configure_headers options[:soap_action]
      configure_ssl
      configure_auth

      @http_request
    end

    private

    def configure_cookies(cookies)
      @http_request.set_cookies(cookies) if cookies
    end

    def configure_headers(soap_action)
      @http_request.headers = @globals[:headers] if @globals.include? :headers
      @http_request.headers["SOAPAction"]   ||= %{"#{soap_action}"} if soap_action
      @http_request.headers["Content-Type"] ||= CONTENT_TYPE[@globals[:soap_version]] % @globals[:encoding]
    end

  end
end
