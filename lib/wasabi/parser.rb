require "uri"
require "wasabi/xpath_helper"
require "wasabi/core_ext/object"
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
      self.types = {}
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

    # Returns the SOAP endpoint.
    attr_accessor :endpoint

    # Returns the elementFormDefault value.
    attr_accessor :element_form_default

    def parse
      parse_namespaces
      parse_endpoint
      parse_operations
      parse_types
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

    def parse_operations
      operations = xpath("wsdl:definitions/wsdl:binding/wsdl:operation")
      operations.each do |operation|
        name = operation.attribute("name").to_s

        soap_action = at_xpath(operation, ".//soap11:operation/@soapAction")
        soap_action ||= at_xpath(operation, ".//soap12:operation/@soapAction")

        if soap_action
          soap_action = soap_action.to_s
          action = soap_action.blank? ? name : soap_action
          input = name.blank? ? action.split("/").last : name
          @operations[input.snakecase.to_sym] = { :action => action, :input => input }
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
    end

    def find_namespace(type)
      schema_namespace = at_xpath(type, "ancestor::xs:schema/@targetNamespace")
      schema_namespace ? schema_namespace.to_s : @namespace
    end

  end
end
