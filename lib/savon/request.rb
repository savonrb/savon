require "httpi"
require "savon/response"
require "savon/log_message"

module Savon
  class Request

    CONTENT_TYPE = {
      1 => "text/xml;charset=%s",
      2 => "application/soap+xml;charset=%s"
    }

    def initialize(operation_name, wsdl, globals, locals)
      @operation_name = operation_name

      @wsdl    = wsdl
      @globals = globals
      @locals  = locals
      @http    = create_http_client
    end

    attr_reader :http

    def call(xml)
      @http.body = xml
      @http.headers["Content-Length"] = xml.bytesize.to_s

      log_request @http.url, @http.headers, @http.body
      response = HTTPI.post(@http)
      log_response response.code, response.body

      response
    end

    private

    def create_http_client
      http = HTTPI::Request.new
      http.url = @globals[:endpoint] || @wsdl.endpoint

      http.proxy = @globals[:proxy] if @globals.include? :proxy
      http.set_cookies @globals[:last_response] if @globals.include? :last_response

      http.open_timeout = @globals[:open_timeout] if @globals.include? :open_timeout
      http.read_timeout = @globals[:read_timeout] if @globals.include? :read_timeout

      http.headers = @globals[:headers] if @globals.include? :headers
      http.headers["SOAPAction"] ||= %{"#{soap_action}"} if soap_action
      http.headers["Content-Type"] = CONTENT_TYPE[@globals[:soap_version]] % @globals[:encoding]

      http.auth.ssl.ssl_version = @globals[:ssl_version] if @globals.include? :ssl_version
      http.auth.ssl.verify_mode = @globals[:ssl_verify_mode] if @globals.include? :ssl_verify_mode

      http.auth.basic(*@globals[:basic_auth]) if @globals.include? :basic_auth
      http.auth.digest(*@globals[:digest_auth]) if @globals.include? :digest_auth

      http
    end

    def soap_action
      return if @locals.include?(:soap_action) && !@locals[:soap_action]
      return @soap_action if defined? @soap_action

      soap_action = @locals[:soap_action]
      soap_action ||= @wsdl.soap_action(@operation_name.to_sym) if @wsdl.document?
      soap_action ||= Gyoku.xml_tag(@operation_name, :key_converter => @globals[:convert_request_keys_to])

      @soap_action = soap_action
    end

    def log_request(url, headers, body)
      logger.info  "SOAP request: #{url}"
      logger.info  headers_to_log(headers)
      logger.debug body_to_log(body)
    end

    def log_response(code, body)
      logger.info  "SOAP response (status #{code})"
      logger.debug body_to_log(body)
    end

    def headers_to_log(headers)
      headers.map { |key, value| "#{key}: #{value}" }.join(", ")
    end

    def body_to_log(body)
      LogMessage.new(body, @globals[:filters], @globals[:pretty_print_xml]).to_s
    end

    def logger
      @globals[:logger]
    end

  end
end
