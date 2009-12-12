module Savon

  # == Savon::Client
  #
  # Heavy metal Ruby SOAP client library. Minimizes the overhead of working
  # with SOAP services and XML.
  class Client

    # Defines whether to use Savon::WSDL.
    @wsdl = true

    class << self
      # Accessor for whether to use Savon::WSDL.
      attr_accessor :wsdl
    end

    # Expects a SOAP +endpoint+ String.
    def initialize(endpoint)
      @request = Request.new endpoint
      @wsdl = WSDL.new @request
    end

    # Accessor for Savon::WSDL.
    attr_accessor :wsdl

    # Returns whether to use Savon::WSDL.
    def wsdl?
      self.class.wsdl && @wsdl
    end

    # Returns +true+ for available methods and SOAP actions.
    def respond_to?(method)
      return true if @wsdl.respond_to? method
      super
    end

  private

    # Dispatches requests to SOAP actions matching a given +method+ name.
    def method_missing(method, *args, &block) #:doc:
      super if wsdl? && !@wsdl.respond_to?(method)

      setup method, &block
      dispatch method
    end

    # Expects a SOAP action and sets up Savon::SOAP and Savon::WSSE.
    # Yields them to a given +block+ in case one was given.
    def setup(soap_action, &block)
      @soap = SOAP.new
      @soap.action = @wsdl.operations[soap_action][:action] if wsdl?
      @soap.input = @wsdl.operations[soap_action][:input] if wsdl?
      @wsse = WSSE.new

      yield_parameters &block if block

      @soap.namespaces["xmlns:wsdl"] ||= @wsdl.namespace_uri if wsdl?
      @soap.wsse = @wsse
    end

    # Yields Savon::SOAP and Savon::WSSE to a given +block+.
    def yield_parameters(&block)
      case block.arity
        when 1 then yield @soap
        when 2 then yield @soap, @wsse
      end
    end

    # Dispatches a given +soap_action+ and returns a Savon::Response instance.
    def dispatch(soap_action)
      response = @request.soap @soap
      Response.new response
    end

  end
end
