class Savon
  class WSDL
    class BindingOperation

      def initialize(operation_node, defaults = {})
        @operation_node = operation_node

        if soap_operation_node = find_soap_operation_node
          namespace = soap_operation_node.first
          node = soap_operation_node.last

          @soap_namespace = namespace
          @soap_action = node['soapAction']
          @style = node['style'] || defaults[:style]
        end
      end

      attr_reader :soap_action, :style, :soap_namespace

      def name
        @operation_node['name']
      end

      # TODO: maybe use proper classes to clean this up.
      def input
        return @input if @input
        input = { header: {}, body: {} }

        input_node = @operation_node.element_children.find { |node| node.name == 'input' }
        return unless input_node

        if header_node = input_node.element_children.find { |node| node.name == 'header' }
          input[:header] = {
            encoding_style: header_node['encodingStyle'],
            namespace:      header_node['namespace'],
            use:            header_node['use'],
            message:        header_node['message'],
            part:           header_node['part']
          }
        end

        if body_node = input_node.element_children.find { |node| node.name == 'body' }
          input[:body] = {
            encoding_style: body_node['encodingStyle'],
            namespace:      body_node['namespace'],
            use:            body_node['use']
          }
        end

        input
      end

      private

      def find_soap_operation_node
        @operation_node.element_children.each do |node|
          namespace = node.namespace.href

          soap_1_1  = namespace == Savon::NS_SOAP_1_1
          soap_1_2  = namespace == Savon::NS_SOAP_1_2
          operation = node.name == 'operation'

          return [namespace, node] if (soap_1_1 || soap_1_2) && operation
        end

        nil
      end

    end
  end
end
