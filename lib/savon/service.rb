require "rexml/document"
require "rubygems"
require "cobravsmongoose"

module Savon

  # == Savon::Service
  #
  # Heavy metal Ruby SOAP client library. This library is supposed to minimize
  # the overhead of working with SOAP services and tries to provide an easy to
  # use alternative to other implementations.
  class Service
    include HTTP

    # XPath to the SOAP fault code by SOAP version. 
    SOAPFaultCodeXpath = { 1 => "//faultcode", 2 => "//code/value" }

    # XPath to the SOAP fault message by SOAP version.
    SOAPFaultMessageXpath = { 1 => "//faultstring", 2 => "//reason/text" }

    # Returns the Net::HTTP response of the last SOAP request.
    attr_reader :response

    # Initializer expects an +endpoint+ URI.
    def initialize(endpoint)
      @endpoint = URI endpoint
    end

    # Returns the Savon::WSDL object.
    def wsdl
      @wsdl ||= WSDL.new @endpoint
    end

    # Returns +true+ for available SOAP actions. Otherwise behaves as usual.
    def respond_to?(method)
      return true if wsdl.soap_actions.include? method
      super
    end

  private

    # Dispatches a SOAP request, handles any HTTP errors and SOAP faults
    # and returns the SOAP response.
    def dispatch(soap_action, soap_body)
      @response = http_soap_call soap_action, soap_body, wsdl.namespace_uri
      raise_soap_fault if soap_fault?
      raise_http_error if http_error?

      savon_config.response_process.call @response
    end

    # Parses the SOAP response for any SOAP fault. Returns a REXML::Element in
    # case a SOAP fault was found. Defaults to +nil+ otherwise.
    def soap_fault
      REXML::Document.new(@response.body).elements["//soap:Fault"]
    end

    alias :soap_fault? :soap_fault

    # Raises a Savon::SOAPFault.
    def raise_soap_fault
      raise SOAPFault, "(#{soap_fault_code}) #{soap_fault_message}"
    end

    # Returns the SOAP fault code.
    def soap_fault_code
      xpath = SOAPFaultCodeXpath[savon_config.soap_version]
      soap_fault.elements[xpath].get_text
    end

    # Returns the SOAP fault message.
    def soap_fault_message
      xpath = SOAPFaultMessageXpath[savon_config.soap_version]
      soap_fault.elements[xpath].get_text
    end

    # Raises a Savon::HTTPError.
    def raise_http_error
      raise HTTPError, "#{@response.message} (#{@response.code}): #{@response.body}"
    end

    # Returns whether the SOAP request returned an HTTP error.
    def http_error?
      @response.code.to_i >= 300
    end

    # Catches calls to SOAP actions, checks if the method called was found
    # in the WSDL and dispatches the SOAP action in case it's valid.
    def method_missing(method, *args, &block)
      soap_action = wsdl.soap_action_for method
      super unless soap_action

      setup_config args.first, block
      soap_body = extract_soap_body args.first

      dispatch soap_action, soap_body
    end

    # Sets up Savon::Config from given +options+ and +response_process+.
    def setup_config(options, response_process)
      savon_config.reset!
      savon_config.response_process = response_process
      savon_config.setup options
    end

    # Returns the SOAP body from given +options+.
    def extract_soap_body(options)
      soap_body = options[:soap_body] if options.kind_of? Hash
      soap_body ? soap_body : options
    end

  end
end
