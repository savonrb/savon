require 'wasabi/binding_operation'

class Wasabi
  class Binding

    def initialize(binding_node)
      @binding_node = binding_node
      @soap_node = find_soap_node
    end

    def name
      @binding_node['name']
    end

    def port_type
      @binding_node['type']
    end

    def style
      @soap_node['style']
    end

    def transport
      @soap_node['transport']
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
        operation = BindingOperation.new(operation_node)

        operations[operation_name] = operation
      end

      operations
    end

    def find_soap_node
      @binding_node.element_children.find { |node|
        namespace = node.namespace.href

        soap_1_1 = namespace == Wasabi::SOAP_1_1
        soap_1_2 = namespace == Wasabi::SOAP_1_2
        binding  = node.name == 'binding'

        (soap_1_1 || soap_1_2) && binding
      }
    end

  end
end
