require 'net/http'
require 'rubygems'
require 'cobravsmongoose'

module Savon
  class HTTP

    attr_reader :response

    attr_writer :namespace_uri

    # Initializer expects an instance of Savon::Options.
    def initialize(options)
      @options = options
    end

    # Retrieves and returns the WSDL document from the Web.
    def retrieve_wsdl
      http.get wsdl_endpoint
    end

    def request(soap_action, soap_body)
      request = Request.new soap_action, soap_body, @namespace_uri, @options

      log_request request.headers, request.body
      @response = http.request_post @options.endpoint.path, request.body, request.headers
      log_response
      
      @response
    end

    # Returns the WSDL endpoint.
    def wsdl_endpoint
      "#{@options.endpoint.path}?#{@options.endpoint.query}"
    end

  private

    def http
      @http ||= Net::HTTP.new @options.endpoint.host, @options.endpoint.port
    end

    def log_request(headers, body)
      Savon.log "SOAP request: #{@endpoint}"
      Savon.log headers.map { |k, v| "#{k}: #{v}" }.join(', ')
      Savon.log body
    end

    def log_response
      Savon.log "SOAP response (status #{@response.code}):"
      Savon.log @response.body
    end

=begin

    # Returns the WSSE arguments if :wsse_username and :wsse_password are set.
    def wsse
      if @wsse_username && @wsse_password
        { :username => @wsse_username, :password => @wsse_password, :digest => wsse_digest? }
      else
        nil
      end
    end

    # Expects a Hash containing information about a SOAP fault and raises
    # a Savon::SOAPFault.
    def raise_soap_fault(soap_fault)
      message = case @version
        when 1
          "#{soap_fault[:faultcode]}: #{soap_fault[:faultstring]}"
        else
          "#{soap_fault[:code][:value]}: #{soap_fault[:reason][:text]}"
      end
      raise SOAPFault, message
    end

    # Expects a Net::HTTPResponse and raises a Savon::HTTPError.
    def raise_http_error(response)
      raise HTTPError, "#{response.message} (#{response.code}): #{response.body}"
    end
=end

  end
end
