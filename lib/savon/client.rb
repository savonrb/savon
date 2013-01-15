require "savon/operation"
require "savon/request"
require "savon/options"
require "savon/block_interface"
require "wasabi"

module Savon
  class Client

    def initialize(globals = {}, &block)
      unless globals.kind_of? Hash
        raise_version1_initialize_error! globals
      end

      @globals = GlobalOptions.new(globals)

      BlockInterface.new(@globals).evaluate(block) if block

      unless wsdl_or_endpoint_and_namespace_specified?
        raise_initialization_error!
      end

      build_wsdl_document
    end

    attr_reader :globals

    def operations
      raise_missing_wsdl_error! unless @wsdl.document?
      @wsdl.soap_actions
    end

    def operation(operation_name)
      Operation.create(operation_name, @wsdl, @globals)
    end

    def call(operation_name, locals = {}, &block)
      response = operation(operation_name).call(locals, &block)
      persist_last_response(response)
      response
    end

    private

    def build_wsdl_document
      @wsdl = Wasabi::Document.new

      @wsdl.document  = @globals[:wsdl]      if @globals.include? :wsdl
      @wsdl.endpoint  = @globals[:endpoint]  if @globals.include? :endpoint
      @wsdl.namespace = @globals[:namespace] if @globals.include? :namespace

      @wsdl.request = WSDLRequest.new(@globals).build
    end

    def persist_last_response(response)
      @globals[:last_response] = response.http
    end

    def wsdl_or_endpoint_and_namespace_specified?
      @globals.include?(:wsdl) || (@globals.include?(:endpoint) && @globals.include?(:namespace))
    end

    def raise_version1_initialize_error!(object)
      raise InitializationError,
        "Some code tries to initialize Savon with the #{object.inspect} (#{object.class}) \n" \
        "Savon 2 expects a Hash of options for creating a new client and executing requests.\n" \
        "Please read the updated documentation for version 2: http://savonrb.com/version2.html"
    end

    def raise_initialization_error!
      raise InitializationError,
            "Expected either a WSDL document or the SOAP endpoint and target namespace options.\n\n" \
            "Savon.client(wsdl: '/Users/me/project/service.wsdl')                              # to use a local WSDL document\n" \
            "Savon.client(wsdl: 'http://example.com?wsdl')                                     # to use a remote WSDL document\n" \
            "Savon.client(endpoint: 'http://example.com', namespace: 'http://v1.example.com')  # if you don't have a WSDL document"
    end

    def raise_missing_wsdl_error!
      raise "Unable to inspect the service without a WSDL document."
    end

  end
end
