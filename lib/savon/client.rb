module Savon

  # = Savon::Client
  #
  # Savon::Client is the main object for connecting to a SOAP service. It includes methods to access
  # both the Savon::WSDL and Savon::Request object.
  #
  # == Instantiation
  #
  # Depending on whether you aim to use Savon with or without Savon::WSDL, you need to instantiate
  # Savon::Client by passing in the WSDL or SOAP endpoint.
  #
  # Client instance with a WSDL endpoint:
  #
  #   client = Savon::Client.new "http://example.com/UserService?wsdl"
  #
  # Client instance with a SOAP endpoint (for using Savon without a WSDL):
  #
  #   client = Savon::Client.new "http://example.com/UserService"
  #
  # It is recommended to not use Savon::WSDL for production. Please take a look at the Documentation
  # for Savon::WSDL for more information about how to disable it.
  #
  # == Using a proxy server
  #
  # You can specify the URI to a proxy server via optional hash arguments.
  #
  #   client = Savon::Client.new "http://example.com/UserService?wsdl", :proxy => "http://proxy.example.com"
  #
  # == Forcing a particular SOAP endpoint
  #
  # In case you don't want to use the SOAP endpoint specified in the WSDL, you can tell Savon to use
  # another SOAP endpoint.
  #
  #   client = Savon::Client.new "http://example.com/UserService?wsdl", :soap_endpoint => "http://localhost/UserService"
  #
  # == Gzipped SOAP requests
  #
  # Sending gzipped SOAP requests can be specified per client instance.
  #
  #   client = Savon::Client.new "http://example.com/UserService?wsdl", :gzip => true
  #
  # == Savon::WSDL
  #
  # You can access Savon::WSDL via:
  #
  #   client.wsdl
  #
  # == Savon::Request
  #
  # You can also access Savon::Request via:
  #
  #   client.request
  class Client

    # Expects a SOAP +endpoint+ string. Also accepts a Hash of +options+.
    #
    # ==== Options:
    #
    # [proxy]  the proxy server to use
    # [gzip]  whether to gzip SOAP requests
    # [soap_endpoint]  force to use this SOAP endpoint
    def initialize(endpoint, options = {})
      soap_endpoint = options.delete(:soap_endpoint)
      @request = Request.new endpoint, options
      @wsdl = WSDL.new @request, soap_endpoint
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

    # Same as method_missing. Workaround for SOAP actions that method_missing does not catch
    # because the method does exist.
    def call(method, *args, &block)
      method_missing method, *args, &block
    end

  private

    # Dispatches requests to SOAP actions matching a given +method+ name.
    def method_missing(method, *args, &block) #:doc:
      soap_action = soap_action_from method.to_s
      super unless @wsdl.respond_to? soap_action

      setup_objects *@wsdl.operation_from(soap_action), &block
      Response.new @request.soap(@soap)
    end

    # Sets whether to use Savon::WSDL by a given +method+ name and returns the original method name
    # without exclamation marks.
    def soap_action_from(method)
      @wsdl.enabled = !method.ends_with?("!")

      method.chop! if method.ends_with?("!")
      method.to_sym
    end

    # Returns the SOAP endpoint.
    def soap_endpoint
      @wsdl.enabled? ? @wsdl.soap_endpoint : @request.endpoint
    end

    # Expects a SOAP operation Hash and sets up Savon::SOAP and Savon::WSSE. Yields them to a given
    # +block+ in case one was given.
    def setup_objects(action, input, &block)
      @soap, @wsse = SOAP.new(action, input, soap_endpoint), WSSE.new
      yield_objects &block if block
      @soap.namespaces["xmlns:wsdl"] ||= @wsdl.namespace_uri if @wsdl.enabled?
      @soap.wsse = @wsse
    end

    # Yields either Savon::SOAP or Savon::SOAP and Savon::WSSE to a given +block+, depending on
    # the number of arguments expected by the block.
    def yield_objects(&block)
      case block.arity
        when 1 then yield @soap
        when 2 then yield @soap, @wsse
      end
    end

  end
end
