require "wasabi/document"
require "httpi/request"
require "akami"

require "savon/soap/xml"
require "savon/soap/request"
require "savon/soap/response"
require "savon/soap/request_builder"

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

    # Returns the <tt>Wasabi::Document</tt>.
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

    # Executes a SOAP request for a given SOAP action. Accepts a +block+ which is evaluated in the
    # context of the <tt>SOAP::RequestBuilder</tt> object to let you access its +soap+, +wsdl+,
    # +http+ and +wsse+ methods.
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

      options = extract_options(args)

      request_builder = SOAP::RequestBuilder.new(options.delete(:input), options)
      request_builder.wsdl = wsdl
      request_builder.http = http.dup
      request_builder.wsse = wsse.dup
      request_builder.config = config.dup

      post_configuration = lambda { process(0, request_builder, &block) if block }

      response = request_builder.request(&post_configuration).response
      http.set_cookies(response.http)

      if wsse.verify_response
        WSSE::VerifySignature.new(response.http.body).verify!
      end

      response
    end

    private

    # Expects an Array of +args+ and returns a Hash containing the SOAP input,
    # the namespace (might be +nil+), the SOAP action (might be +nil+),
    # the SOAP body (might be +nil+), and a Hash of attributes for the input
    # tag (which might be empty).
    def extract_options(args)
      attributes = Hash === args.last ? args.pop : {}
      body = attributes.delete(:body)
      soap_action = attributes.delete(:soap_action)

      namespace_identifier = args.size > 1 ? args.shift.to_sym : nil
      input = args.first

      remove_blank_values(
        :namespace_identifier => namespace_identifier,
        :input                => input,
        :attributes           => attributes,
        :body                 => body,
        :soap_action          => soap_action
      )
    end

    # Processes a given +block+. Yields objects if the block expects any arguments.
    # Otherwise evaluates the block in the context of +instance+.
    def process(offset = 0, instance = self,  &block)
      block.arity > 0 ? yield_objects(offset, instance, &block) : evaluate(instance, &block)
    end

    # Yields a number of objects to a given +block+ depending on how many arguments
    # the block is expecting.
    def yield_objects(offset, instance, &block)
      to_yield = [:soap, :wsdl, :http, :wsse]
      yield *(to_yield[offset, block.arity].map { |obj_name| instance.send(obj_name) })
    end

    # Evaluates a given +block+ inside +instance+. Stores the original block binding.
    def evaluate(instance, &block)
      original_self = eval "self", block.binding

      # A proxy that attemps to make method calls on +instance+. If a NoMethodError is
      # raised, the call will be made on +original_self+.
      proxy = Object.new
      proxy.instance_eval do
        class << self
          attr_accessor :original_self, :instance
        end

        def method_missing(method, *args, &block)
          instance.send(method, *args, &block)
        rescue NoMethodError
          original_self.send(method, *args, &block)
        end
      end

      proxy.instance = instance
      proxy.original_self = original_self

      proxy.instance_eval &block
    end

    # Removes all blank values from a given +hash+.
    def remove_blank_values(hash)
      hash.delete_if { |_, value| value.respond_to?(:empty?) ? value.empty? : !value }
    end

  end
end
