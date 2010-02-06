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
      soap_action = soap_action_from method.to_s
      super unless @wsdl.respond_to? soap_action

      setup_objects @wsdl.operation_from(soap_action), &block
      Response.new @request.soap(@soap)
    end

    # Sets whether to use Savon::WSDL by a given +method+ name and
    # removes exclamation marks from the given +method+ name.
    def soap_action_from(method)
      @wsdl.enabled = !method.ends_with?("!")

      method.chop! if method.ends_with?("!")
      method.to_sym
    end

    # Returns the SOAP endpoint.
    def soap_endpoint
      @wsdl.enabled? ? @wsdl.soap_endpoint : @request.endpoint
    end

    # Expects a SOAP operation Hash and sets up Savon::SOAP and Savon::WSSE.
    # Yields them to a given +block+ in case one was given.
    def setup_objects(operation, &block)
      @soap, @wsse = SOAP.new(operation, soap_endpoint), WSSE.new
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
