require "logger"
require "net/http"
require "rubygems"
require "cobravsmongoose"

module Savon
  module HTTP

    @@logger = Logger.new STDOUT

    @@log_level = :debug

    def self.logger
      @@logger
    end

    def self.logger=(logger)
      @@logger = logger
    end

    def self.log_level
      @@log_level
    end

    def self.log_level=(log_level)
      @@log_level = log_level
    end

    attr_reader :http_request

    # Retrieves and returns the WSDL document from the Web.
    def http_get_wsdl
      log "Retrieving WSDL from: #{@endpoint}"
      http.get @endpoint.to_s
    end

    def http_soap_call(soap_action, soap_body, namespace_uri = nil)
      setup_http_request soap_action, soap_body, namespace_uri

      log_request
      @http_response = http.request_post *soap_call_arguments
      log_response

      @http_response
    end

  private

    def http
      @http ||= Net::HTTP.new @endpoint.host, @endpoint.port
    end

    def setup_http_request(soap_action, soap_body, namespace_uri)
      @http_request ||= Request.new
      @http_request.soap_action = soap_action
      @http_request.soap_body = soap_body
      @http_request.namespace_uri = namespace_uri if namespace_uri
    end

    def log_request
      log "SOAP request: #{@endpoint}"
      log @http_request.headers.map { |k, v| "#{k}: #{v}" }.join ", "
      log @http_request.body
    end

    def soap_call_arguments
      [@endpoint.path, @http_request.body, @http_request.headers]
    end

    def log_response
      log "SOAP response (status #{@http_response.code}):"
      log @http_response.body
    end

    # Logs a given +message+ using the +@@logger+ instance or yields the logger
    # to a given +block+.
    def log(message)
      HTTP.logger.send HTTP.log_level, message if HTTP.logger.respond_to? HTTP.log_level
    end

  end
end
