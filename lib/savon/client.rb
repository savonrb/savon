module Savon

  # == Savon::Client
  #
  # Heavy metal Ruby SOAP client library. Minimizes the overhead of working
  # with SOAP services and XML.
  class Client
    include Validation

    @response_block = lambda do |response|
      hash = Crack::XML.parse(response.body)["soap:Envelope"]["soap:Body"]
      hash = hash[hash.keys.first]["return"] rescue hash[hash.keys.first]
      hash.map_soap_response
    end

    class << self
      attr_accessor :response_block
    end

    # Expects a SOAP +endpoint+ String.
    def initialize(endpoint)
      @request = Request.new endpoint
      @wsdl = WSDL.new @request
    end

    # Returns the Savon::WSDL object.
    attr_reader :response, :wsdl

    # Dispatches a given +soap_action+ with a given +soap_body+ and +options+.
    def dispatch(soap_action, soap_body, options, response_block = nil)
      @soap = SOAP.new soap_action, soap_body, options, @wsdl.namespace_uri
      @response = @request.soap @soap
      response_process(response_block).call @response
    end

    # Behaves as usual, but also returns +true+ for available SOAP actions.
    def respond_to?(method)
      return true if @wsdl.soap_actions.include? method
      super
    end

  private

    # Behaves as usual, but dispatches SOAP requests to SOAP actions matching
    # the given +method+ name.
    def method_missing(method, *args, &block)
      soap_action = @wsdl.mapped_soap_actions[method]
      super unless soap_action

      soap_body, options = args[0], args[1] || {}
      validate_arguments! soap_body, options, block
      dispatch soap_action, soap_body, options, block
    end

    def response_process(response_block)
      response_block || self.class.response_block 
    end

    # Validates a given +soap_body+ and +options+.
    def validate_arguments!(soap_body, options = {}, response_block = nil)
      validate! :soap_body, soap_body if soap_body
      validate! :response_block, response_block if response_block
      validate! :soap_version, options[:soap_version] if options[:soap_version]
      validate! :wsse_credentials, options[:wsse] if options[:wsse].kind_of? Hash
    end

  end
end
