class Wasabi
  class BindingOperation

    def initialize(operation_node, defaults = {})
      @operation_node = operation_node

      if soap_operation_node = find_soap_operation_node
        @soap_action = soap_operation_node['soapAction']
        @style = soap_operation_node['style'] || defaults[:style]
      end
    end

    attr_reader :soap_action, :style

    def name
      @operation_node['name']
    end

    def input
      return @input if @input

      input = @operation_node.element_children.find { |node| node.name == 'input' }
      return unless input

      body = input.element_children.find { |node| node.name == 'body' }
      return unless body

      @input = {
        :encoding_style => body['encodingStyle'],
        :namespace => body['namespace'],
        :use => body['use']
      }
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
