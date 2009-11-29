module Savon

  # == Savon::Client
  #
  # Heavy metal Ruby SOAP client library. Minimizes the overhead of working
  # with SOAP services and XML.
  class Client
    include Validation

    # Default behavior for processing the SOAP response. Expects an instance
    # of Net::HTTPResponse and returns the SOAP response body as a Hash.
    @response_process = lambda do |response|
      response_hash = Crack::XML.parse response.body
      error_handling.call response, response_hash

      response_hash = response_hash["soap:Envelope"]["soap:Body"]
      response_hash = response_hash[response_hash.keys.first]
      (response_hash["return"] || response_hash).map_soap_response
    end

    # Default error handling. Expects an instance of Net::HTTPResponse and
    # a SOAP response body Hash. Raises a Savon::SOAPFault in case of a SOAP
    # fault or a Savon::HTTPError in case of an HTTP error.
    @error_handling = lambda do |response, response_hash|
      soap_fault = response_hash.to_soap_fault_message
      raise Savon::SOAPFault, soap_fault if soap_fault

      http_error = "#{response.message} (#{response.code})"
      http_error += ": #{response.body}" unless response.body.empty?
      raise Savon::HTTPError, http_error if response.code.to_i >= 300
    end

    class << self

      # Accessor for the default response block.
      attr_accessor :response_process

      # Accessor for the default error handling.
      attr_accessor :error_handling

    end

    # Expects a SOAP +endpoint+ String.
    def initialize(endpoint)
      @request = Request.new endpoint
      @wsdl = WSDL.new @request
    end

    # Returns the Savon::WSDL.
    attr_reader :wsdl

    # Returns the Net::HTTPResponse of the last SOAP request.
    attr_reader :response

    # Behaves as usual, but also returns +true+ for available SOAP actions.
    def respond_to?(method)
      return true if @wsdl.soap_actions.include? method
      super
    end

  private

    # Behaves as usual, but dispatches SOAP requests to SOAP actions matching
    # the given +method+ name.
    def method_missing(method, *args, &block) #:doc:
      soap_action = @wsdl.mapped_soap_actions[method]
      super unless soap_action

      soap_body, options = args[0] || {}, args[1] || {}
      validate_arguments! soap_body, options, block
      dispatch soap_action, soap_body, options, block
    end

    # Dispatches a given +soap_action+ with a given +soap_body+, +options+
    # and a +block+.
    def dispatch(soap_action, soap_body, options, block = nil)
      @soap = SOAP.new soap_action, soap_body, options, @wsdl.namespace_uri
      @response = @request.soap @soap
      response_process(block).call @response
    end

    # Returns the response process to use.
    def response_process(block)
      block || self.class.response_process
    end

    # Validates the given +soap_body+, +options+ and +response_process+.
    def validate_arguments!(soap_body, options = {}, response_process = nil)
      validate! :soap_body, soap_body if soap_body
      validate! :response_process, response_process if response_process
      validate! :soap_version, options[:soap_version] if options[:soap_version]
      validate! :wsse_credentials, options[:wsse] if options[:wsse].kind_of? Hash
    end

  end
end
