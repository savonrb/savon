require "httpi/request"
require "akami"

require "savon/wasabi/document"
require "savon/soap/xml"
require "savon/soap/request"
require "savon/soap/response"

module Savon

  # = Savon::Client
  #
  # Savon::Client is the main object for connecting to a SOAP service.
  class Client

    # Initializes the Savon::Client for a SOAP service. Accepts a +block+ which is evaluated in the
    # context of this object to let you access the +wsdl+, +http+, and +wsse+ methods.
    #
    # == Examples
    #
    #   # Using a remote WSDL
    #   client = Savon::Client.new("http://example.com/UserService?wsdl")
    #
    #   # Using a local WSDL
    #   client = Savon::Client.new File.expand_path("../wsdl/service.xml", __FILE__)
    #
    #   # Directly accessing a SOAP endpoint
    #   client = Savon::Client.new do
    #     wsdl.endpoint = "http://example.com/UserService"
    #     wsdl.namespace = "http://users.example.com"
    #   end
    def initialize(wsdl_document = nil, &block)
      wsdl.document = wsdl_document if wsdl_document
      process 1, &block if block
      wsdl.request = http
    end

    # Returns the <tt>Savon::Wasabi::Document</tt>.
    def wsdl
      @wsdl ||= Wasabi::Document.new
    end

    # Returns the <tt>HTTPI::Request</tt>.
    def http
      @http ||= HTTPI::Request.new
    end

    # Returns the <tt>Akami::WSSE</tt> object.
    def wsse
      @wsse ||= Akami.wsse
    end

    # Returns the <tt>Savon::SOAP::XML</tt> object. Please notice, that this object is only available
    # in a block given to <tt>Savon::Client#request</tt>. A new instance of this object is created
    # per SOAP request.
    attr_reader :soap

    # Executes a SOAP request for a given SOAP action. Accepts a +block+ which is evaluated in the
    # context of this object to let you access the +soap+, +wsdl+, +http+ and +wsse+ methods.
    #
    # == Examples
    #
    #   # Calls a "getUser" SOAP action with the payload of "<userId>123</userId>"
    #   client.request(:get_user) { soap.body = { :user_id => 123 } }
    #
    #   # Prefixes the SOAP input tag with a given namespace: "<wsdl:GetUser>...</wsdl:GetUser>"
    #   client.request(:wsdl, "GetUser") { soap.body = { :user_id => 123 } }
    #
    #   # SOAP input tag with attributes: <getUser xmlns:wsdl="http://example.com">...</getUser>"
    #   client.request(:get_user, "xmlns:wsdl" => "http://example.com")
    def request(*args, &block)
      raise ArgumentError, "Savon::Client#request requires at least one argument" if args.empty?

      self.soap = SOAP::XML.new
      preconfigure extract_options(args)
      process &block if block
      soap.wsse = wsse

      response = SOAP::Request.new(http, soap).response
      set_cookie response.http.headers
      response
    end

  private

    # Writer for the <tt>Savon::SOAP::XML</tt> object.
    attr_writer :soap

    # Accessor for the original self of a given block.
    attr_accessor :original_self

    # Passes a cookie from the last request +headers+ to the next one.
    def set_cookie(headers)
      http.headers["Cookie"] = headers["Set-Cookie"] if headers["Set-Cookie"]
    end

    # Expects an Array of +args+ and returns an Array containing the namespace (might be +nil+),
    # the SOAP input and a Hash of attributes for the input tag (which might be empty).
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
      soap.element_form_default = wsdl.element_form_default if wsdl.document?
      soap.body = options[2].delete(:body)

      set_soap_action options[1]
      set_soap_input *options
    end

    # Expects an +input+ and sets the +SOAPAction+ HTTP headers.
    def set_soap_action(input)
      soap_action = wsdl.soap_action(input.to_sym) if wsdl.document?
      soap_action ||= Gyoku::XMLKey.create(input).to_sym
      http.headers["SOAPAction"] = %{"#{soap_action}"}
    end

    # Expects a +namespace+, +input+ and +attributes+ and sets the SOAP input.
    def set_soap_input(namespace, input, attributes)
      new_input = wsdl.soap_input(input.to_sym) if wsdl.document?
      new_input ||= Gyoku::XMLKey.create(input)
      soap.input = [namespace, new_input.to_sym, attributes].compact
    end

    # Processes a given +block+. Yields objects if the block expects any arguments.
    # Otherwise evaluates the block in the context of this object.
    def process(offset = 0, &block)
      block.arity > 0 ? yield_objects(offset, &block) : evaluate(&block)
    end

    # Yields a number of objects to a given +block+ depending on how many arguments
    # the block is expecting.
    def yield_objects(offset, &block)
      yield *[soap, wsdl, http, wsse][offset, block.arity]
    end

    # Evaluates a given +block+ inside this object. Stores the original block binding.
    def evaluate(&block)
      self.original_self = eval "self", block.binding
      instance_eval &block
    end

    # Handles calls to undefined methods by delegating to the original block binding.
    def method_missing(method, *args, &block)
      super unless original_self
      original_self.send method, *args, &block
    end

  end
end
