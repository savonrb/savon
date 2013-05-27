require 'wasabi/message_builder'

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

    def soap_action
      @binding_operation.soap_action
    end

    def soap_version
      case @binding_operation.soap_namespace
      when Wasabi::SOAP_1_1 then '1.1'
      when Wasabi::SOAP_1_2 then '1.2'
      end
    end

    def input_style
      "#{@binding_operation.style}/#{@binding_operation.input[:use]}"
    end

    def input
      parts = parts_for_input_output @port_type_operation.input
      MessageBuilder.new(self, @wsdl).build(parts)
    end

    def output_style
      "#{@binding_operation.style}/#{@binding_operation.output[:use]}"
    end

    def output
      parts = parts_for_input_output @port_type_operation.output
      MessageBuilder.new(self, @wsdl).build(parts)
    end

    private

    def parts_for_input_output(input_output)
      message = find_message input_output[:message]
      message.parts
    end

    def find_message(qname)
      local = qname.split(':').last

      @wsdl.documents.messages[local] or
        raise "Unable to find message #{qname.inspect}"
    end

  end
end
