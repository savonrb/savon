require "uri"
require "wasabi/xpath_helper"
require "wasabi/core_ext/string"

module Wasabi

  # = Wasabi::Parser
  #
  # Parses WSDL documents and remembers their important parts.
  class Parser
    include XPathHelper

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
      parse_operations
      parse_types
      parse_deferred_types
    end

    def parse_namespaces
      element_form_default = at_xpath("wsdl:definitions/wsdl:types/xs:schema/@elementFormDefault")
      @element_form_default = element_form_default.to_s.to_sym if element_form_default

      namespace = at_xpath("wsdl:definitions/@targetNamespace")
      @namespace = namespace.to_s if namespace

      @namespaces = @document.namespaces.inject({}) do |memo, (key, value)|
        memo[key.sub("xmlns:", "")] = value
        memo
      end
    end

    def parse_endpoint
      endpoint = at_xpath("wsdl:definitions/wsdl:service//soap11:address/@location")
      endpoint ||= at_xpath("wsdl:definitions/wsdl:service//soap12:address/@location")

      begin
        @endpoint = URI(URI.escape(endpoint.to_s)) if endpoint
      rescue URI::InvalidURIError
        @endpoint = nil
      end
    end

    def parse_service_name
      service_name = at_xpath("wsdl:definitions/@name")
      @service_name = service_name.to_s if service_name
    end

    def parse_operations
      operations = xpath("wsdl:definitions/wsdl:binding/wsdl:operation")
      operations.each do |operation|
        name = operation.attribute("name").to_s

        soap_action = at_xpath(operation, ".//soap11:operation/@soapAction")
        soap_action ||= at_xpath(operation, ".//soap12:operation/@soapAction")

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
      xpath("wsdl:definitions/wsdl:types/xs:schema/xs:element[@name]").
        each { |type| process_type(at_xpath(type, "./xs:complexType"), type.attribute("name").to_s) }

      xpath("wsdl:definitions/wsdl:types/xs:schema/xs:complexType[@name]").
        each { |type| process_type(type, type.attribute("name").to_s) }
    end

    def process_type(type, name)
      return unless type
      @types[name] ||= { :namespace => find_namespace(type) }

      xpath(type, "./xs:sequence/xs:element").
        each { |inner| @types[name][inner.attribute("name").to_s] = { :type => inner.attribute("type").to_s } }

      type.xpath("./xs:complexContent/xs:extension/xs:sequence/xs:element",
        "xs" => "http://www.w3.org/2001/XMLSchema"
      ).each do |inner_element|
        @types[name][inner_element.attribute('name').to_s] = {
          :type => inner_element.attribute('type').to_s
        }
      end

      type.xpath('./xs:complexContent/xs:extension[@base]',
        "xs" => "http://www.w3.org/2001/XMLSchema"
      ).each do |inherits|
        base = inherits.attribute('base').value.match(/\w+$/).to_s
        if @types[base]
          @types[name].merge! @types[base]
        else
          deferred_types << Proc.new {
            @types[name].merge! @types[base] if @types[base]
          }
        end
      end
    end

    def parse_deferred_types
      deferred_types.each(&:call)
    end

    def find_namespace(type)
      schema_namespace = at_xpath(type, "ancestor::xs:schema/@targetNamespace")
      schema_namespace ? schema_namespace.to_s : @namespace
    end

    def input_for(operation)
      operation_name = operation["name"]

      # Look up the input by walking up to portType, then up to the message.

      binding_type = at_xpath(operation, "../@type").to_s.split(':').last
      port_type_input = at_xpath(operation, "../../wsdl:portType[@name='#{binding_type}']/wsdl:operation[@name='#{operation_name}']/wsdl:input")

      # TODO: Stupid fix for missing support for imports.
      # Sometimes portTypes are actually included in a separate WSDL.
      if port_type_input
        port_message_ns_id, port_message_type = port_type_input.attribute("message").to_s.split(':')

        message_ns_id, message_type = nil

        # TODO: Support multiple 'part' elements in the message.
        if (port_message_part = at_xpath(port_type_input, "../../../wsdl:message[@name='#{port_message_type}']/wsdl:part[1]"))
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
