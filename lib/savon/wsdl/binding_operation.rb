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
      def input_headers
        return @input_headers if @input_headers
        input_headers = []

        if header_nodes = find_input_child_nodes('header')
          header_nodes.each do |header_node|
            input_headers << {
              encoding_style: header_node['encodingStyle'],
              namespace:      header_node['namespace'],
              use:            header_node['use'],
              message:        header_node['message'],
              part:           header_node['part']
            }
          end
        end

        @input_headers = input_headers
      end

      # TODO: maybe use proper classes to clean this up.
      def input_body
        return @input_body if @input_body
        input_body = {}

        if body_node = find_input_child_nodes('body').first
          input_body = {
            encoding_style: body_node['encodingStyle'],
            namespace:      body_node['namespace'],
            use:            body_node['use']
          }
        end

        @input_body = input_body
      end

      private

      def find_input_child_nodes(child_name)
        input_node = @operation_node.element_children.find { |node| node.name == 'input' }
        return unless input_node

        input_node.element_children.select { |node| node.name == child_name }
      end

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
