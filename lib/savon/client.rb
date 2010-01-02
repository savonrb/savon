module Savon

  # == Savon::Client
  #
  # Heavy metal Ruby SOAP client library. Minimizes the overhead of working
  # with SOAP services and XML.
  class Client

    # Expects a SOAP +endpoint+ String. Also accepts an optional Hash of
    # +options+ for specifying a proxy server and SSL client authentication.
    def initialize(endpoint, options = {})
      @request = Request.new endpoint, options
      @wsdl = WSDL.new @request
    end

    # Returns the Savon::WSDL.
    attr_reader :wsdl

    # Returns the Savon::Request.
    attr_reader :request

    # Returns +true+ for available methods and SOAP actions.
    def respond_to?(method)
      return true if @wsdl.respond_to? method
      super
    end

  private

    # Dispatches requests to SOAP actions matching a given +method+ name.
    def method_missing(method, *args, &block) #:doc:
      soap_call = soap_call_from method.to_s
      super if @wsdl.enabled? && !@wsdl.respond_to?(soap_call)

      setup_objects operation_from(soap_call), &block
      Response.new @request.soap(@soap)
    end

    # Sets whether to use Savon::WSDL by a given +method+ name and
    # removes exclamation marks from the given +method+ name.
    def soap_call_from(method)
      if method[-1, 1] == "!"
        @wsdl.enabled = false
        method[0, method.length-1].to_sym
      else
        @wsdl.enabled = true
        method.to_sym
      end
    end

    # Returns a SOAP operation Hash containing the SOAP action and input
    # for a given +soap_call+.
    def operation_from(soap_call)
      return @wsdl.operations[soap_call] if @wsdl.enabled?
      { :action => soap_call.to_soap_key, :input => soap_call.to_soap_key }
    end

    # Returns the SOAP endpoint.
    def soap_endpoint
      @wsdl.enabled? ? @wsdl.soap_endpoint : @request.endpoint
    end

    # Expects a SOAP operation Hash and sets up Savon::SOAP and Savon::WSSE.
    # Yields them to a given +block+ in case one was given.
    def setup_objects(operation, &block)
      @soap, @wsse = SOAP.new, WSSE.new
      @soap.action, @soap.input, @soap.endpoint = operation[:action], operation[:input], soap_endpoint

      yield_objects &block if block

      @soap.namespaces["xmlns:wsdl"] ||= @wsdl.namespace_uri if @wsdl.enabled?
      @soap.wsse = @wsse
    end

    # Yields Savon::SOAP and Savon::WSSE to a given +block+.
    def yield_objects(&block)
      case block.arity
        when 1 then yield @soap
        when 2 then yield @soap, @wsse
      end
    end

  end
end
