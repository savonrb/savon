require "httpi"
require "savon/response"

module Savon
  class Request

    CONTENT_TYPE = {
      1 => "text/xml;charset=%s",
      2 => "application/soap+xml;charset=%s"
    }

    def initialize(globals, locals)
      @globals = globals
      @locals = locals
      @http = create_http_client
    end

    attr_reader :http

    def call(xml)
      @http.body = xml  # TODO: implement soap.signature? [dh, 2012-12-09]
      @http.headers["Content-Length"] = xml.bytesize.to_s

      log_request @http.url, @http.headers, @http.body
      response = HTTPI.post(@http)
      log_response response.code, response.body

      Response.new(response, @globals, @locals)
    end

    private

    def create_http_client
      http = HTTPI::Request.new
      http.url = @globals[:endpoint]

      http.proxy = @globals[:proxy] if @globals.include? :proxy
      http.set_cookies @globals[:last_response] if @globals.include? :last_response

      http.open_timeout = @globals[:open_timeout] if @globals.include? :open_timeout
      http.read_timeout = @globals[:read_timeout] if @globals.include? :read_timeout

      http.headers = @globals[:headers] if @globals.include? :headers
      http.headers["SOAPAction"] ||= %{"#{@locals[:soap_action]}"} if @locals.include? :soap_action
      http.headers["Content-Type"] = content_type

      http.auth.basic *@globals[:basic_auth] if @globals.include? :basic_auth
      http.auth.digest *@globals[:digest_auth] if @globals.include? :digest_auth

      http
    end

    def content_type
      CONTENT_TYPE[@globals[:soap_version]] % @globals[:encoding]
    end

    def log_request(url, headers, body)
      log "SOAP request: #{url}"
      log headers.map { |key, value| "#{key}: #{value}" }.join(", ")
      log body, :pretty => @globals[:pretty_print_xml], :filter => true
    end

    def log_response(code, body)
      log "SOAP response (status #{code}):"
      log body, :pretty => @globals[:pretty_print_xml]
    end

    def log(message, options = {})
      @globals[:logger].log(message, options)
    end

  end
end
