class Savon
  class WSDL

    class Input

      def initialize(binding_operation, port_type_operation, wsdl)
        @binding_operation = binding_operation
        @port_type_operation = port_type_operation
        @wsdl = wsdl

        build_parts
      end

      # Public: Returns the header part Elements.
      attr_reader :header_parts

      # Public: Returns the body part Elements.
      attr_reader :body_parts

      private

      def build_parts
        body_parts = collect_body_parts
        header_parts = collect_header_parts

        # remove explicit header parts from the body parts
        header_part_names = header_parts.map { |part| part[:name] }
        body_parts.reject! { |part| header_part_names.include? part[:name] }

        @header_parts = ElementBuilder.new(@wsdl.schemas).build(header_parts)
        @body_parts = ElementBuilder.new(@wsdl.schemas).build(body_parts)
      end

      def collect_body_parts
        find_message(message_name).parts
      end

      def message_name
        @port_type_operation.input[:message]
      end

      def collect_header_parts
        parts = []

        headers.each do |header|
          next unless header[:message] && header[:part]
          message_parts = find_message(header[:message]).parts

          # only add the single header part from the message
          parts << message_parts.find { |part| part[:name] == header[:part] }
        end

        parts
      end

      def headers
        @binding_operation.input_headers
      end

      def find_message(qname)
        local = qname.split(':').last

        @wsdl.documents.messages[local] or
          raise "Unable to find message #{qname.inspect}"
      end

    end

    class Output < Input

      private

      def message_name
        @port_type_operation.output[:message]
      end

      def headers
        @binding_operation.output_headers
      end

    end

  end
end
