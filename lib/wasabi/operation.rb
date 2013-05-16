require 'wasabi/param_factory'

class Wasabi
  class Operation

    def initialize(name, endpoint, binding_operation, port_type_operation, wsdl)
      @name = name
      @endpoint = endpoint
      @binding_operation = binding_operation
      @port_type_operation = port_type_operation

      @wsdl = wsdl
    end

    attr_reader :name, :endpoint, :binding_operation, :port_type_operation

    def input
      @input = ParamFactory.new(self, @wsdl).build
    end

    def soap_action
      @binding_operation.soap_action
    end

    def style
      @binding_operation.style
    end

  end
end
