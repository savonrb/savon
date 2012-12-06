require "savon/operation"
require "wasabi"

module Savon
  class NewClient

    def initialize(wsdl_locator)
      @wsdl = Wasabi::Document.new(wsdl_locator)
    end

    def operations
      @wsdl.soap_actions
    end

    def operation(operation_name)
      Operation.create(operation_name, @wsdl)
    end

    def call(operation_name, options = {})
      operation(operation_name).call(options)
    end

  end
end
