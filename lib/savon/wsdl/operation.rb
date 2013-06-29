require 'savon/wsdl/input_output'
require 'savon/element_builder'

class Savon
  class WSDL
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
        when Savon::NS_SOAP_1_1 then '1.1'
        when Savon::NS_SOAP_1_2 then '1.2'
        end
      end

      def input
        @input ||= Input.new(@binding_operation, @port_type_operation, @wsdl)
      end

      def output
        @output ||= Output.new(@binding_operation, @port_type_operation, @wsdl)
      end

      def input_style
        "#{@binding_operation.style}/#{@binding_operation.input_body[:use]}"
      end

      def output_style
        "#{@binding_operation.style}/#{@binding_operation.output[:body][:use]}"
      end

    end
  end
end
