require 'wasabi/core_ext/string'
require 'wasabi/operation'

class Wasabi
  class Operations

    def initialize(parser)
      @parser = parser

      @operations = {}
      parse
    end

    attr_accessor :operations

    def parse
      parse_messages
      parse_port_types
      parse_port_type_operations
      parse_operations
    end

    def parse_messages
      messages = @parser.document.root.element_children.select { |node| node.name == 'message' }
      @messages = Hash[messages.map { |node| [node['name'], node] }]
    end

    def parse_port_types
      port_types = @parser.document.root.element_children.select { |node| node.name == 'portType' }
      @port_types = Hash[port_types.map { |node| [node['name'], node] }]
    end

    def parse_port_type_operations
      @port_type_operations = {}

      @port_types.each do |port_type_name, port_type|
        operations = port_type.element_children.select { |node| node.name == 'operation' }
        @port_type_operations[port_type_name] = Hash[operations.map { |node| [node['name'], node] }]
      end
    end

    def parse_operations
      operations = @parser.document.xpath("wsdl:definitions/wsdl:binding/wsdl:operation", 'wsdl' => Wasabi::WSDL)
      operations.each do |operation|
        name = operation.attribute("name").to_s

        # TODO: check for soap namespace?
        soap_operation = operation.element_children.find { |node| node.name == 'operation' }
        soap_action = soap_operation['soapAction'] if soap_operation

        if soap_action
          soap_action = soap_action.to_s
          action = soap_action && !soap_action.empty? ? soap_action : name

          # There should be a matching portType for each binding, so we will lookup the input from there.
          nsid, input = input_for(operation)

          # Store namespace identifier so this operation can be mapped to the proper namespace.
          @operations[name.snakecase.to_sym] = Operation.new(:soap_action => action, :input => input, :nsid => nsid)
        elsif !@operations[name.snakecase.to_sym]
          @operations[name.snakecase.to_sym] = Operation.new(:soap_action => name, :input => name)
        end
      end
    end

    def input_for(operation)
      operation_name = operation["name"]

      # Look up the input by walking up to portType, then up to the message.

      binding_type = operation.parent['type'].to_s.split(':').last
      if @port_type_operations[binding_type]
        port_type_operation = @port_type_operations[binding_type][operation_name]
      end

      port_type_input = port_type_operation && port_type_operation.element_children.find { |node| node.name == 'input' }

      # TODO: Stupid fix for missing support for imports.
      # Sometimes portTypes are actually included in a separate WSDL.
      if port_type_input
        port_message_ns_id, port_message_type = port_type_input.attribute("message").to_s.split(':')

        message_ns_id, message_type = nil

        # TODO: Support multiple 'part' elements in the message.
        message = @messages[port_message_type]
        port_message_part = message.element_children.find { |node| node.name == 'part' }

        if port_message_part
          if (port_message_part_element = port_message_part.attribute("element"))
            message_ns_id, message_type = port_message_part_element.to_s.split(':')
          end
        end

        # Fall back to the name of the binding operation
        if message_type
          [message_ns_id, message_type]
        else
          [port_message_ns_id, operation_name]
        end
      else
        [nil, operation_name]
      end
    end

  end
end
