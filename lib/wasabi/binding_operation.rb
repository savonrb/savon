class Wasabi
  class BindingOperation

    def initialize(operation_node)
      @operation_node = operation_node
      @soap_operation_node = find_soap_operation_node
    end

    def name
      @operation_node['name']
    end

    def soap_action
      @soap_operation_node['soapAction']
    end

    def style
      @soap_operation_node['style']
    end

    def to_hash
      { :name => name, :soap_action => soap_action, :style => style }
    end

    private

    def find_soap_operation_node
      @operation_node.element_children.find { |node|
        namespace = node.namespace.href

        soap_1_1  = namespace == Wasabi::SOAP_1_1
        soap_1_2  = namespace == Wasabi::SOAP_1_2
        operation = node.name == 'operation'

        (soap_1_1 || soap_1_2) && operation
      }
    end

  end
end
