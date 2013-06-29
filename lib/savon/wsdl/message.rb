class Savon
  class WSDL
    class Message

      def initialize(message_node)
        @message_node = message_node
      end

      def name
        @message_node['name']
      end

      def parts
        @parts ||= parts!
      end

      private

      def parts!
        parts = []

        @message_node.element_children.each do |part|
          next unless part.name == 'part'

          parts << {
            :name       => part['name'],
            :type       => part['type'],
            :element    => part['element'],
            :namespaces => part.namespaces
          }
        end

        parts
      end

    end
  end
end
