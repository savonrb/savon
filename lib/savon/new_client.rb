require "savon/operation"
require "savon/options"
require "wasabi"

module Savon
  class NewClient

    def initialize(wsdl_locator, options = {})
      @options = Options.new
      @options.set(:global, options)

      @wsdl = Wasabi::Document.new(wsdl_locator)
      @wsdl.endpoint = @options.endpoint if @options.endpoint
    end

    attr_reader :options

    def operations
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

  end
end
