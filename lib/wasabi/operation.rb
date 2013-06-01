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
      "#{@binding_operation.style}/#{@binding_operation.input[:body][:use]}"
    end

    def input
      @input ||= build_message(@port_type_operation.input)
    end

    def output_style
      "#{@binding_operation.style}/#{@binding_operation.output[:body][:use]}"
    end

    def output
      @output ||= build_message(@port_type_operation.output)
    end

    private

    def build_message(input_output)
      message_name = input_output[:message]
      parts = find_message(message_name).parts

      MessageBuilder.new(@wsdl).build(parts)
    end

    def find_message(qname)
      local = qname.split(':').last

      @wsdl.documents.messages[local] or
        raise "Unable to find message #{qname.inspect}"
    end

  end
end
