require 'savon/wsdl/binding_operation'

class Savon
  class WSDL
    class Binding

      def initialize(binding_node)
        @binding_node = binding_node

        if soap_node = find_soap_node
          @style = soap_node['style'] || 'document'
          @transport = soap_node['transport']
        end
      end

      attr_reader :style, :transport

      def name
        @binding_node['name']
      end

      def port_type
        @binding_node['type']
      end

      def operations
        @operations ||= operations!
      end

      private

      def operations!
        operations = {}

        @binding_node.element_children.each do |operation_node|
          next unless operation_node.name == 'operation'

          operation_name = operation_node['name']
          operation = BindingOperation.new(operation_node, :style => @style)

          operations[operation_name] = operation
        end

        operations
      end

      def find_soap_node
        @binding_node.element_children.find { |node|
          namespace = node.namespace.href

          soap_1_1 = namespace == Savon::NS_SOAP_1_1
          soap_1_2 = namespace == Savon::NS_SOAP_1_2
          binding  = node.name == 'binding'

          (soap_1_1 || soap_1_2) && binding
        }
      end

    end
  end
end
