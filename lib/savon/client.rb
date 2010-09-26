require "savon/soap"
require "savon/wsdl/document"
require "savon/request"
require "savon/wsse"
require "savon/response"

module Savon

  # = Savon::Client
  #
  # Savon::Client is the main object for connecting to a SOAP service. It includes methods to access
  # both the Savon::WSDL::Document and Savon::Request object.
  #
  # == Instantiation
  #
  # Depending on whether you aim to use Savon with or without Savon::WSDL, you need to instantiate
  # Savon::Client by passing in the WSDL and/or SOAP endpoint.
  #
  # Client instance with a WSDL endpoint:
  #
  #   client = Savon::Client.new :wsdl => "http://example.com/UserService?wsdl"
  #
  # Client instance with a SOAP endpoint (for using Savon without a WSDL):
  #
  #   client = Savon::Client.new :soap_endpoint => "http://example.com/UserService"
  #
  # It is recommended to not use Savon::WSDL::Document for production. Please take a look at the
  # documentation for Savon::WSDL for more information about how to disable it.
  #
  # == Using a proxy server
  #
  # You can specify the URI to a proxy server via optional hash arguments.
  #
  #   client = Savon::Client.new :wsdl => "http://example.com/UserService?wsdl",
  #     :proxy => "http://proxy.example.com"
  #
  # == Forcing a particular SOAP endpoint
  #
  # In case you don't want to use the SOAP endpoint specified in the WSDL, you can tell Savon to use
  # another SOAP endpoint.
  #
  #   client = Savon::Client.new :wsdl => "http://example.com/UserService?wsdl",
  #     :soap_endpoint => "http://localhost/UserService"
  #
  # == Gzipped SOAP requests
  #
  # Sending gzipped SOAP requests can be specified per client instance.
  #
  #   client = Savon::Client.new :wsdl => "http://example.com/UserService?wsdl", :gzip => true
  #
  # == Savon::WSDL::Document
  #
  # You can access the Savon::WSDL::Document via:
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
    # [soap_endpoint]  the SOAP endpoint to use
    # [wsdl]           the wsdl to use
    # [proxy]          the proxy server to use
    # [gzip]           whether to gzip SOAP requests
    def initialize(options = {})
      raise ArgumentError, "Please specify a :wsdl and/or :soap_endpoint" unless options[:wsdl] || options[:soap_endpoint]
      
      soap_endpoint = options.delete :soap_endpoint
      @request = Request.new options
      @wsdl = WSDL::Document.new @request, soap_endpoint
    end

    # Returns the Savon::WSDL::Document.
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
      soap_action = method
      super unless @wsdl.respond_to? soap_action

      setup_objects *@wsdl.operation_from(soap_action), &block
      Response.new @request.soap(@soap)
    end

    # Expects a SOAP operation Hash and sets up Savon::SOAP and Savon::WSSE. Yields them to a given
    # +block+ in case one was given.
    def setup_objects(action, input, &block)
      @soap, @wsse = SOAP.new(action, input, @wsdl.soap_endpoint), WSSE.new
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
