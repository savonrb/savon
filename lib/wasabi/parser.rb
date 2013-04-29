require "uri"
require "wasabi/core_ext/string"

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
      self.document = document
      self.operations = {}
      self.namespaces = {}
      self.service_name = ''
      self.types = {}
      self.deferred_types = []
      self.element_form_default = :unqualified
    end

    # Returns the Nokogiri document.
    attr_accessor :document

    # Returns the target namespace.
    attr_accessor :namespace

    # Returns a map from namespace identifier to namespace URI.
    attr_accessor :namespaces

    # Returns the SOAP operations.
    attr_accessor :operations

    # Returns a map from a type name to a Hash with type information.
    attr_accessor :types

    # Returns a map of deferred type Proc objects.
    attr_accessor :deferred_types

    # Returns the SOAP endpoint.
    attr_accessor :endpoint

    # Returns the SOAP Service Name
    attr_accessor :service_name

    # Returns the elementFormDefault value.
    attr_accessor :element_form_default

    def parse
      parse_namespaces
      parse_endpoint
      parse_service_name
      parse_messages
      parse_port_types
      parse_port_type_operations
      parse_operations
      parse_types
      parse_deferred_types
    end

    def parse_namespaces
      element_form_default = schemas.first && schemas.first['elementFormDefault']
      @element_form_default = element_form_default.to_s.to_sym if element_form_default

      namespace = document.root['targetNamespace']
      @namespace = namespace.to_s if namespace

      @namespaces = @document.namespaces.inject({}) do |memo, (key, value)|
        memo[key.sub("xmlns:", "")] = value
        memo
      end
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
      service_name = document.root['name']
      @service_name = service_name.to_s if service_name
    end

    def parse_messages
      messages = document.root.element_children.select { |node| node.name == 'message' }
      @messages = Hash[messages.map { |node| [node['name'], node] }]
    end

    def parse_port_types
      port_types = document.root.element_children.select { |node| node.name == 'portType' }
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
      operations = document.xpath("wsdl:definitions/wsdl:binding/wsdl:operation", 'wsdl' => WSDL)
      operations.each do |operation|
        name = operation.attribute("name").to_s

        # TODO: check for soap namespace?
        soap_operation = operation.element_children.find { |node| node.name == 'operation' }
        soap_action = soap_operation['soapAction'] if soap_operation

        if soap_action
          soap_action = soap_action.to_s
          action = soap_action && !soap_action.empty? ? soap_action : name

          # There should be a matching portType for each binding, so we will lookup the input from there.
          namespace_id, input = input_for(operation)

          # Store namespace identifier so this operation can be mapped to the proper namespace.
          @operations[name.snakecase.to_sym] = { :action => action, :input => input, :namespace_identifier => namespace_id }
        elsif !@operations[name.snakecase.to_sym]
          @operations[name.snakecase.to_sym] = { :action => name, :input => name }
        end
      end
    end

    def parse_types
      schemas.each do |schema|
        schema_namespace = schema['targetNamespace']

        schema.element_children.each do |node|
          namespace = schema_namespace || @namespace

          case node.name
          when 'element'
            process_type namespace, node.at_xpath('./xs:complexType', 'xs' => XSD), node['name'].to_s
          when 'complexType'
            process_type namespace, node, node['name'].to_s
          end
        end
      end
    end

    def process_type(namespace, type, name)
      return unless type
      @types[name] ||= { :namespace => namespace }

      type.xpath("./xs:sequence/xs:element", 'xs' => XSD).
        each { |inner| @types[name][inner.attribute("name").to_s] = { :type => inner.attribute("type").to_s } }

      type.xpath("./xs:complexContent/xs:extension/xs:sequence/xs:element", 'xs' => XSD).each do |inner_element|
        @types[name][inner_element.attribute('name').to_s] = {
          :type => inner_element.attribute('type').to_s
        }
      end

      type.xpath('./xs:complexContent/xs:extension[@base]', 'xs' => XSD).each do |inherits|
        base = inherits.attribute('base').value.match(/\w+$/).to_s

        if @types[base]
          @types[name].merge! @types[base]
        else
          deferred_types << Proc.new { @types[name].merge! @types[base] if @types[base] }
        end
      end
    end

    def parse_deferred_types
      deferred_types.each(&:call)
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

    def schemas
      types = section('types').first
      types ? types.element_children : []
    end

    def service
      services = section('service')
      services.first if services  # service nodes could be imported?
    end

    def section(section_name)
      sections[section_name] || []
    end

    def sections
      return @sections if @sections

      sections = {}
      document.root.element_children.each do |node|
        (sections[node.name] ||= []) << node
      end

      @sections = sections
    end

  end
end
