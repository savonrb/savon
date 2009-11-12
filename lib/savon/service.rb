require 'rubygems'
require 'hpricot'
require 'cobravsmongoose'

module Savon

  # == Savon::Service
  #
  # Savon::Service is a SOAP client library to enjoy. The goal is to minimize
  # the overhead of working with SOAP services and provide a lightweight
  # alternative to other libraries.
  class Service

    attr_reader :response

    def options
      setup_infrastructure unless @options
      @options
    end

    def http
      setup_infrastructure unless @http
      @http
    end

    def wsdl
      setup_infrastructure unless @wsdl
      @wsdl
    end

    # Initializer expects an +endpoint+ URI.
    def initialize(endpoint)
      @endpoint = endpoint
    end

  private

    # Dispatches a SOAP request, handles any HTTP errors and SOAP faults
    # and returns the SOAP response.
    def dispatch(soap_action, soap_body)
      response = @http.request soap_action, soap_body

      soap_fault = Hpricot.XML(response.body).at '//soap:Fault'
      raise_soap_fault soap_fault if soap_fault
      raise_http_error response if response.code.to_i >= 300

      @options.process_response.call response
    end

    # Expects a Hpricot document containing a Soap:Fault node and raises
    # a Savon::SOAPFault.
    def raise_soap_fault(soap_fault)
      case @options.soap_version
        when 1
          code_node, info_node = '//faultcode', '//faultstring'
        else
          code_node, info_node = '//code/value', '//reason/text'
      end
      code = soap_fault.at(code_node).inner_text
      info = soap_fault.at(info_node).inner_text

      raise SOAPFault, "#{code}: #{info}"
    end

    # Expects a Net::HTTPResponse and raises a Savon::HTTPError.
    def raise_http_error(response)
      raise HTTPError, "#{response.message} (#{response.code}): #{response.body}"
    end

    # Catches calls to SOAP actions, checks if the method called was found
    # in the WSDL and dispatches the SOAP action if it's valid.
    def method_missing(method, *args)
      setup_infrastructure
      soap_action = @wsdl.soap_action_for method
      soap_body = extract_soap_body args[0]

      super unless soap_action
      dispatch soap_action, soap_body
    end

    def setup_infrastructure
      @options = Options.new
      @options.endpoint = @endpoint
      @http = HTTP.new @options
      @wsdl = WSDL.new @http, @options
      @http.namespace_uri = @wsdl.namespace_uri
    end

    # Returns the SOAP body from given +args+.
    def extract_soap_body(args)
      args = args[:soap_body] if args.kind_of? Hash
      args.kind_of?(String) ? args : ""
    end

    # Converts a given +string+ from snake_case to lowerCamelCase.
    def camelize(string)
      string.to_s.gsub(/_(.)/) { $1.upcase } if string
    end

  end
end
