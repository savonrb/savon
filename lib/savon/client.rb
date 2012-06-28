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
      self.config = Savon.config.clone
      wsdl.document = wsdl_document if wsdl_document

      process 1, &block if block
      wsdl.request = http
    end

    # Accessor for the <tt>Savon::Config</tt>.
    attr_accessor :config

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

      self.soap = SOAP::XML.new(config)
      preconfigure extract_options(args)
      process &block if block
      soap.wsse = wsse

      response = SOAP::Request.new(config, http, soap).response
      http.set_cookies(response.http)

      if wsse.verify_response
        WSSE::VerifySignature.new(response.http.body).verify!
      end

      response
    end

    private

    # Writer for the <tt>Savon::SOAP::XML</tt> object.
    attr_writer :soap

    # Accessor for the original self of a given block.
    attr_accessor :original_self

    # Expects an Array of +args+ and returns an Array containing the namespace (might be +nil+),
    # the SOAP input and a Hash of attributes for the input tag (which might be empty).
    def extract_options(args)
      attributes = Hash === args.last ? args.pop : {}
      namespace = args.size > 1 ? args.shift.to_sym : nil
      input = args.first

      [namespace, input, attributes]
    end

    # Expects an Array of +args+ to preconfigure the system.
    def preconfigure(args)
      soap.endpoint = wsdl.endpoint
      soap.element_form_default = wsdl.element_form_default

      body = args[2].delete(:body)
      soap.body = body if body

      wsdl.type_namespaces.each do |path, uri|
        soap.use_namespace(path, uri)
      end

      wsdl.type_definitions.each do |path, type|
        soap.types[path] = type
      end

      soap_action = args[2].delete(:soap_action) || args[1]
      set_soap_action soap_action

      request_deprecations!(args)

      if wsdl.document? && (operation = wsdl.operations[args[1]]) && operation[:namespace_identifier]
        soap.namespace_identifier = operation[:namespace_identifier].to_sym
        soap.namespace = wsdl.parser.namespaces[soap.namespace_identifier.to_s]

        # Override nil namespace with one specified in WSDL
        args[0] = soap.namespace_identifier unless args[0]
      else
        soap.namespace_identifier = args[0]
        soap.namespace = wsdl.namespace
      end

      set_soap_input *args
    end

    # Expects an +input+ and sets the +SOAPAction+ HTTP headers.
    def set_soap_action(input_tag)
      soap_action = wsdl.soap_action(input_tag.to_sym) if wsdl.document?
      soap_action ||= Gyoku::XMLKey.create(input_tag).to_sym
      http.headers["SOAPAction"] = %{"#{soap_action}"}
    end

    # Expects a +namespace+, +input+ and +attributes+ and sets the SOAP input.
    def set_soap_input(namespace, input, attributes)
      new_input_tag = wsdl.soap_input(input.to_sym) if wsdl.document?
      new_input_tag ||= Gyoku::XMLKey.create(input)
      soap.input = [namespace, new_input_tag.to_sym, attributes]
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

    def request_deprecations!(args)
      if args[0]
        deprecate "DEPRECATION: You passed #{args[0].inspect} as a namespace to Savon::Client#request\n" +
                  "Please remove the namespace argument from the call as this feature will be removed in Savon v2.\n" +
                  "Open an issue at https://github.com/rubiii/savon/issues if this doesn't work for you."
      end
      if args[1].kind_of?(String)
        deprecate "DEPRECATION: You passed #{args[1].inspect} as the operation name to Savon::Client#request\n" +
                  "Please run client.soap_actions, find the (Symbol) name of your operation and use that instead.\n" +
                  "Open an issue at https://github.com/rubiii/savon/issues if this doesn't work for you."
      end
      unless args[2].empty?
        deprecate "DEPRECATION: You passed #{args[2].inspect} to Savon::Client#request\n" +
                  "Open an issue at https://github.com/rubiii/savon/issues if you need these attributes."
      end
    end

    def deprecate(message)
      config.logger.log message
      puts message
    end

  end
end
