require "httpi/request"
require "savon/soap/xml"
require "savon/soap/request"
require "savon/soap/response"
require "savon/wsdl/document"
require "savon/wsse"
require "savon/delegator"

module Savon

  # = Savon::Client
  #
  # The main interface for interacting with SOAP services.
  class Client
    include Delegator

    # Initializes the Savon::Client for a SOAP service. Accepts a +block+ which is either evaluated
    # in the context of +self+ or being called with +self+ if the block expects an argument.
    #
    # == Examples
    #
    #   # Using a remote WSDL
    #   client = Savon::Client.new { wsdl.document = "http://example.com/UserService?wsdl" }
    #
    #   # Using a local WSDL
    #   client = Savon::Client.new { wsdl.document = "../wsdl/user_service.xml" }
    #
    #   # Shortcut for setting the WSDL
    #   client = Savon::Client.new "http://example.com/UserService?wsdl"
    #
    #   # You can pass a block to use Savon without a WSDL by defining the
    #   # SOAP endpoint and the target namespace manually
    #   client = Savon::Client.new do
    #     wsdl.endpoint = "http://example.com/UserService"
    #     wsdl.namespace = "http://users.example.com"
    #   end
    def initialize(wsdl_document = nil, &block)
      wsdl.document = wsdl_document if wsdl_document
      process &block if block
      wsdl.request = http
    end

    # Returns the <tt>Savon::WSDL::Document</tt>.
    def wsdl
      @wsdl ||= WSDL::Document.new
    end

    # Returns the <tt>HTTPI::Request</tt>.
    def http
      @http ||= HTTPI::Request.new
    end

    # Returns the <tt>Savon::WSSE</tt>.
    def wsse
      @wsse ||= WSSE.new
    end

    # Returns the <tt>Savon::SOAP::XML</tt>. Notice, that this object is only available
    # in a block passed to <tt>Savon::Client#request</tt>. A new instance of this object
    # is created per SOAP request.
    def soap
      raise ArgumentError, "Expected to be called in a block passed to #request" unless @soap
      @soap
    end

    attr_writer :soap

    # Executes a SOAP request for a given SOAP action. Accepts a +block+ which is either evaluated
    # in the context of +self+ or being called with +self+ if the block expects an argument.
    #
    # == Examples
    #
    #   # Calls a "getUser" SOAP action with the SOAP body of "<userId>123</userId>"
    #   client.request(:get_user) { soap.body = { :user_id => 123 } }
    #
    #   # Namespaces the SOAP input tag with a given namespace: "<wsdl:GetUser>...</wsdl:GetUser>"
    #   client.request(:wsdl, "GetUser") { soap.body = { :user_id => 123 } }
    #
    #   # SOAP input tag with attributes: <getUser xmlns:wsdl="http://example.com">...</getUser>"
    #   client.request(:get_user, "xmlns:wsdl" => "http://example.com")
    def request(*args, &block)
      raise ArgumentError, "Expected to receive at least one argument" if args.empty?

      self.soap = SOAP::XML.new
      preconfigure extract_options(args)
      process &block if block
      soap.wsse = wsse

      response = SOAP::Request.new(http, soap).response
      set_cookie response.http.headers
      response
    end

  private

    # Passes a cookie from the last request +headers+ to the next one.
    def set_cookie(headers)
      http.headers["Cookie"] = headers["Set-Cookie"] if headers["Set-Cookie"]
    end

    # Expects an Array of +args+ and returns an Array containing the namespace (might be +nil+),
    # the SOAP input and a Hash of attributes for the input tag (might be empty).
    def extract_options(args)
      attributes = Hash === args.last ? args.pop : {}
      namespace = args.size > 1 ? args.shift.to_sym : nil
      input = args.first

      [namespace, input, attributes]
    end

    # Expects and Array of +options+ and preconfigures the system.
    def preconfigure(options)
      soap.endpoint = wsdl.endpoint
      soap.namespace_identifier = options[0]
      soap.namespace = wsdl.namespace
      soap.element_form_default = wsdl.element_form_default if wsdl.present?
      soap.body = options[2].delete(:body) if options[2][:body]

      set_soap_action options[1]
      set_soap_input *options
    end

    # Expects an +input+ and sets the +SOAPAction+ HTTP headers.
    def set_soap_action(input)
      soap_action = wsdl.soap_action input.to_sym
      soap_action ||= Gyoku::XMLKey.create(input).to_sym
      http.headers["SOAPAction"] = %{"#{soap_action}"}
    end

    # Expects a +namespace+, +input+ and +attributes+ and sets the SOAP input.
    def set_soap_input(namespace, input, attributes)
      new_input = wsdl.soap_input input.to_sym
      new_input ||= Gyoku::XMLKey.create(input).to_sym
      soap.input = [namespace, new_input, attributes].compact
    end

  end
end
