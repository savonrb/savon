require "savon/operation"
require "savon/options"
require "wasabi"

module Savon
  class Client

    def initialize(globals = {})
      @globals = GlobalOptions.new(globals)

      unless wsdl_or_endpoint_and_namespace_specified?
        raise_initialization_error!
      end

      @wsdl = Wasabi::Document.new
      @wsdl.document = @globals[:wsdl] if @globals.include? :wsdl
      @wsdl.endpoint = @globals[:endpoint] if @globals.include? :endpoint
      @wsdl.namespace = @globals[:namespace] if @globals.include? :namespace
    end

    attr_reader :globals

    def operations
      raise "Unable to inspect the service without a WSDL document." unless @wsdl.document?
      @wsdl.soap_actions
    end

    def operation(operation_name)
      Operation.create(operation_name, @wsdl, @globals)
    end

    def call(operation_name, locals = {})
      response = operation(operation_name).call(locals)
      @globals[:last_response] = response.http
      response
    end

    private

    def wsdl_or_endpoint_and_namespace_specified?
      @globals.include?(:wsdl) || (@globals.include?(:endpoint) && @globals.include?(:namespace))
    end

    def raise_initialization_error!
      raise ArgumentError, "Expected either a WSDL document or the SOAP endpoint and target namespace options.\n\n" \
                           "Savon.client(wsdl: '/Users/me/project/service.wsdl')                              # to use a local WSDL document\n" \
                           "Savon.client(wsdl: 'http://example.com?wsdl')                                     # to use a remote WSDL document\n" \
                           "Savon.client(endpoint: 'http://example.com', namespace: 'http://v1.example.com')  # if you don't have a WSDL document"
    end

  end
end
