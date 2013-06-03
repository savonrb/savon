require 'savon/wsdl/message_builder'

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

      def header_parts
        build_parts unless @header_parts
        @header_parts
      end

      def body_parts
        build_parts unless @body_parts
        @body_parts
      end

      def input_style
        "#{@binding_operation.style}/#{@binding_operation.input_body[:use]}"
      end

      def output_style
        "#{@binding_operation.style}/#{@binding_operation.output[:body][:use]}"
      end

      # TODO: do something useful with this!
      def output
        @output ||= build_message(@port_type_operation.output)
      end

      private

      def build_parts
        body_parts = collect_body_parts
        header_parts = collect_header_parts

        # remove explicit header parts from the body parts
        header_part_names = header_parts.map { |part| part[:name] }
        body_parts.reject! { |part| header_part_names.include? part[:name] }

        @header_parts = MessageBuilder.new(@wsdl).build(header_parts)
        @body_parts = MessageBuilder.new(@wsdl).build(body_parts)
      end

      def collect_body_parts
        message_name = @port_type_operation.input[:message]
        find_message(message_name).parts
      end

      def collect_header_parts
        parts = []

        @binding_operation.input_headers.each do |header|
          next unless header[:message] && header[:part]
          message_parts = find_message(header[:message]).parts

          # only add the single header part from the message
          parts << message_parts.find { |part| part[:name] == header[:part] }
        end

        parts
      end

      def build_message(input_output)
        message_name = input_output[:message]
        parts = find_message(message_name).parts

        MessageBuilder.new(@wsdl).build(parts)
      end

      def find_message(qname)
        local = qname.split(':').last

        @wsdl.documents.messages[local] or
          raise "Unable to find message #{qname.inspect}"
      end

    end
  end
end
