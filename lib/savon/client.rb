module Savon

  # == Savon::Client
  #
  # Heavy metal Ruby SOAP client library. Minimizes the overhead of working
  # with SOAP services and XML.
  class Client

    # Global setting of whether to use Savon::WSDL.
    @@wsdl = true

    # Sets the global setting of whether to use Savon::WSDL.
    def self.wsdl=(wsdl)
      @@wsdl = wsdl
    end

    # Returns the global setting of whether to use Savon::WSDL.
    def self.wsdl?
      @@wsdl
    end

    # Expects a SOAP +endpoint+ String. Also accepts an optional Hash of
    # +options+ for specifying a proxy server and SSL client authentication.
    def initialize(endpoint,options = {})
      @request = Request.new endpoint, options
      @wsdl = WSDL.new @request
    end

    # Accessor for Savon::WSDL.
    attr_accessor :wsdl

    # Returns the Savon::Request.
    attr_reader :request

    # Returns whether to use Savon::WSDL.
    def wsdl?
      self.class.wsdl? && @wsdl
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

      setup operation_from(method), &block
      dispatch method
    end

    # Returns a SOAP operation Hash containing the SOAP action and input
    # for a given +method+.
    def operation_from(method)
      return @wsdl.operations[method] if wsdl?
      { :action => method.to_soap_key, :input => method.to_soap_key }
    end

    # Expects a SOAP operation Hash and sets up Savon::SOAP and Savon::WSSE.
    # Yields them to a given +block+ in case one was given.
    def setup(operation, &block)
      @soap = SOAP.new
      @soap.action, @soap.input = operation[:action], operation[:input]
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
