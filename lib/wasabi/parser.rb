require "uri"
require "wasabi/core_ext/string"
require "wasabi/schema_collection"
require 'wasabi/schema'
require "wasabi/operation"

module Wasabi

  # = Wasabi::Parser
  #
  # Parses WSDL documents and remembers their important parts.
  class Parser

    XSD      = "http://www.w3.org/2001/XMLSchema"
    WSDL     = "http://schemas.xmlsoap.org/wsdl/"
    SOAP_1_1 = "http://schemas.xmlsoap.org/wsdl/soap/"
    SOAP_1_2 = "http://schemas.xmlsoap.org/wsdl/soap12/"

    def initialize(document)
      @document = document
      @operations = {}
      @service_name = ''
    end

    def target_namespace
      @document.root['targetNamespace']
    end

    def namespaces
      @namespaces ||= collect_namespaces(@document, *schema_nodes)
    end

    def namespaces_by_value
      @namespaces_by_value ||= namespaces.invert
    end

    def schemas
      @schemas ||= begin
        schemas = schema_nodes.map { |node| Schema.new(node, self) }
        SchemaCollection.new(schemas)
      end
    end

    def schema_nodes
      @schema_nodes ||= begin
        types = @document.at_xpath('/wsdl:definitions/wsdl:types', 'wsdl' => WSDL)
        types ? types.element_children : []
      end
    end

    # Returns the SOAP operations.
    attr_accessor :operations

    # Returns the SOAP endpoint.
    attr_accessor :endpoint

    # Returns the SOAP Service Name
    attr_accessor :service_name

    def parse
      parse_endpoint
      parse_service_name
      parse_messages
      parse_port_types
      parse_port_type_operations
      parse_operations
    end

    def collect_namespaces(*nodes)
      namespaces = {}

      nodes.each do |node|
        node.namespaces.each do |k, v|
          key = k.sub(/^xmlns:/, '')
          namespaces[key] = v
        end
      end

      namespaces.delete('xmlns')
      namespaces
    end

    def parse_endpoint
      if service_node = service
        endpoint = service_node.at_xpath(".//soap11:address/@location", 'soap11' => SOAP_1_1)
        endpoint ||= service_node.at_xpath(service_node, ".//soap12:address/@location", 'soap12' => SOAP_1_2)
      end

      begin
        @endpoint = URI(URI.escape(endpoint.to_s)) if endpoint
      rescue URI::InvalidURIError
        @endpoint = nil
      end
    end

    def parse_service_name
      service_name = @document.root['name']
      @service_name = service_name.to_s if service_name
    end

    def parse_messages
      messages = @document.root.element_children.select { |node| node.name == 'message' }
      @messages = Hash[messages.map { |node| [node['name'], node] }]
    end

    def parse_port_types
      port_types = @document.root.element_children.select { |node| node.name == 'portType' }
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
      operations = @document.xpath("wsdl:definitions/wsdl:binding/wsdl:operation", 'wsdl' => WSDL)
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

    def service
      @document.at_xpath('/wsdl:definitions/wsdl:service', 'wsdl' => WSDL)
    end

  end
end
