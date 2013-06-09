require 'savon/element_builder'

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

      def input
        @input ||= InputOutput.new(:input, @binding_operation, @port_type_operation, @wsdl)
      end

      def output
        @output ||= InputOutput.new(:output, @binding_operation, @port_type_operation, @wsdl)
      end

      class InputOutput

        def initialize(input_output, binding_operation, port_type_operation, wsdl)
          # XXX: Get rid of this via inheritance if this works?
          @input_output = input_output
          @input_output_headers = "#{input_output}_headers"

          @binding_operation = binding_operation
          @port_type_operation = port_type_operation
          @wsdl = wsdl

          build_parts
        end

        attr_reader :header_parts, :body_parts

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
          message_name = @port_type_operation.send(@input_output)[:message]
          find_message(message_name).parts
        end

        def collect_header_parts
          parts = []

          @binding_operation.send(@input_output_headers).each do |header|
            next unless header[:message] && header[:part]
            message_parts = find_message(header[:message]).parts

            # only add the single header part from the message
            parts << message_parts.find { |part| part[:name] == header[:part] }
          end

          parts
        end

        def find_message(qname)
          local = qname.split(':').last

          @wsdl.documents.messages[local] or
            raise "Unable to find message #{qname.inspect}"
        end

      end

      def input_style
        "#{@binding_operation.style}/#{@binding_operation.input_body[:use]}"
      end

      def output_style
        "#{@binding_operation.style}/#{@binding_operation.output[:body][:use]}"
      end

    end
  end
end
