require 'savon/wsdl/binding_operation'

class Savon
  class WSDL
    class Binding

      def initialize(binding_node)
        @binding_node = binding_node

        @name = binding_node['name']
        @port_type = binding_node['type']

        if soap_node = find_soap_node
          @style = soap_node['style'] || 'document'
          @transport = soap_node['transport']
        end
      end

      attr_reader :name, :port_type, :style, :transport

      def fetch_port_type(documents)
        port_type_local = @port_type.split(':').last

        documents.port_types.fetch(port_type_local) {
          raise "Unable to find portType #{port_type_local.inspect} for binding #{@name.inspect}"
        }
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
