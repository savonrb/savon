require "rexml/document"
require "rubygems"
require "cobravsmongoose"

module Savon

  # == Savon::Service
  #
  # Savon::Service is a SOAP client library to enjoy. The goal is to minimize
  # the overhead of working with SOAP services and provide a lightweight
  # alternative to other libraries.
  class Service
    include HTTP

    SOAPFaultCodeXpath = { 1 => "//faultcode", 2 => "//code/value" }

    SOAPFaultMessageXpath = { 1 => "//faultstring", 2 => "//reason/text" }

    attr_reader :response

    # Initializer expects an +endpoint+ URI.
    def initialize(endpoint)
      @endpoint = URI endpoint
    end

    def wsdl
      @wsdl ||= WSDL.new @endpoint
    end

    def respond_to?(method)
      return true if wsdl.soap_actions.respond_to? method
      super
    end

  private

    # Dispatches a SOAP request, handles any HTTP errors and SOAP faults
    # and returns the SOAP response.
    def dispatch(soap_action, soap_body)
      @response = http_soap_call soap_action, soap_body, wsdl.namespace_uri
      raise SOAPFault, "(#{soap_fault_code}) #{soap_fault_message}" if soap_fault?
      raise HTTPError, "#{@response.message} (#{@response.code}): #{@response.body}" if http_error?

      savon_config.response_process.call @response
    end

    def soap_fault
      @soap_fault ||= REXML::Document.new(@response.body).elements["//soap:Fault"]
    end

    alias :soap_fault? :soap_fault

    def soap_fault_code
      xpath = SOAPFaultCodeXpath[savon_config.soap_version]
      soap_fault.elements[xpath].get_text
    end

    def soap_fault_message
      xpath = SOAPFaultMessageXpath[savon_config.soap_version]
      soap_fault.elements[xpath].get_text
    end

    # Expects a Net::HTTPResponse and raises a Savon::HTTPError.
    def http_error?
      @response.code.to_i >= 300
    end

    # Catches calls to SOAP actions, checks if the method called was found
    # in the WSDL and dispatches the SOAP action if it"s valid.
    def method_missing(method, *args, &block)
      soap_action = wsdl.soap_action_for method
      super unless soap_action

      setup_config args.first, block
      soap_body = extract_soap_body args.first

      dispatch soap_action, soap_body
    end

    def setup_config(options, response_process)
      savon_config.reset!
      savon_config.response_process = response_process
      savon_config.setup options
    end

    # Returns the SOAP body from given +args+.
    def extract_soap_body(options)
      soap_body = options[:soap_body] if options.kind_of? Hash
      soap_body ? soap_body : options
    end

  end
end
