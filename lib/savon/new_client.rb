require "savon/operation"
require "savon/options"
require "wasabi"

module Savon
  class NewClient

    def initialize(options)
      @options = Options.new_with_defaults.merge(:global, options)

      unless @options.wsdl || (@options.endpoint && @options.namespace)
        raise_initialization_error!
      end

      @wsdl = Wasabi::Document.new
      @wsdl.document = @options.wsdl if @options.wsdl
      @wsdl.endpoint = @options.endpoint if @options.endpoint
      @wsdl.namespace = @options.namespace if @options.namespace
    end

    attr_reader :options

    def operations
      raise "Unable to inspect the service without a WSDL document." unless @wsdl.document?
      @wsdl.soap_actions
    end

    def operation(operation_name)
      Operation.create(operation_name, @wsdl, @options)
    end

    def call(operation_name, options = {})
      response = operation(operation_name).call(options)
      @options.add(:global, :last_response, response.http)
      response
    end

    private

    def raise_initialization_error!
      raise ArgumentError, "Expected either a WSDL document or the SOAP endpoint and target namespace options.\n\n" \
                           "Savon.new_client(wsdl: '/Users/me/project/service.wsdl')                              # to use a local WSDL document\n" \
                           "Savon.new_client(wsdl: 'http://example.com?wsdl')                                     # to use a remote WSDL document\n" \
                           "Savon.new_client(endpoint: 'http://example.com', namespace: 'http://v1.example.com')  # if you don't have a WSDL document"
    end

  end
end
