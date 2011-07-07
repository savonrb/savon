require "uri"
require "wasabi/core_ext/object"
require "wasabi/core_ext/string"

module Wasabi

  # = Wasabi::Parser
  #
  # Parses WSDL documents and remembers their important parts.
  class Parser

    def initialize(nokogiri_document)
      @document = nokogiri_document
      @operations = {}
      @namespaces = {}
      @types = {}
      @element_form_default = :unqualified
    end

    # Returns the target namespace.
    attr_reader :namespace

    # Returns a map from namespace identifier to namespace URI.
    attr_reader :namespaces

    # Returns the SOAP operations.
    attr_reader :operations

    # Returns a map from a type name to a Hash with type information.
    attr_reader :types

    # Returns the SOAP endpoint.
    attr_reader :endpoint

    # Returns the elementFormDefault value.
    attr_reader :element_form_default

    def parse
      parse_namespaces
      parse_endpoint
      parse_operations
      parse_types
    end

    def parse_namespaces
      element_form_default = @document.at_xpath(
        "s0:definitions/s0:types/xs:schema/@elementFormDefault",
        "s0" => "http://schemas.xmlsoap.org/wsdl/",
        "xs" => "http://www.w3.org/2001/XMLSchema")
      @element_form_default = element_form_default.to_s.to_sym if element_form_default

      namespace = @document.at_xpath(
        "s0:definitions/@targetNamespace",
        "s0" => "http://schemas.xmlsoap.org/wsdl/")
      @namespace = namespace.to_s if namespace

      @namespaces = @document.collect_namespaces.inject({}) do |result, (key, value)|
        result.merge(key.gsub(/xmlns:/, '') => value)
      end
    end

    def parse_endpoint
      endpoint = @document.at_xpath(
        "s0:definitions/s0:service//soap11:address/@location",
        "s0" => "http://schemas.xmlsoap.org/wsdl/",
        "soap11" => "http://schemas.xmlsoap.org/wsdl/soap/")
      endpoint ||= @document.at_xpath(
        "s0:definitions/s0:service//soap12:address/@location",
        "s0" => "http://schemas.xmlsoap.org/wsdl/",
        "soap12" => "http://schemas.xmlsoap.org/wsdl/soap12/")

      @endpoint = URI(URI.escape(endpoint.to_s)) if endpoint
    end

    def parse_operations
      operations = @document.xpath(
        "s0:definitions/s0:binding/s0:operation",
        "s0" => "http://schemas.xmlsoap.org/wsdl/")
      operations.each do |operation|
        name = operation.attribute("name").to_s

        soap_action = operation.at_xpath(".//soap11:operation/@soapAction",
          "soap11" => "http://schemas.xmlsoap.org/wsdl/soap/"
        )
        soap_action ||= operation.at_xpath(".//soap12:operation/@soapAction",
          "soap12" => "http://schemas.xmlsoap.org/wsdl/soap12/"
        )

        if soap_action
          soap_action = soap_action.to_s

          action = soap_action.blank? ? name : soap_action
          input = name.blank? ? action.split("/").last : name

          @operations[input.snakecase.to_sym] =
            { :action => action, :input => input }
        elsif !@operations[name.snakecase.to_sym]
          @operations[name.snakecase.to_sym] =
            { :action => name, :input => name }
        end
      end
    end

    def parse_types
      @document.xpath(
        "s0:definitions/s0:types/xs:schema/xs:element[@name]",
        "s0" => "http://schemas.xmlsoap.org/wsdl/",
        "xs" => "http://www.w3.org/2001/XMLSchema"
      ).each do |type|
        process_type(type.at_xpath('./xs:complexType',
          "xs" => "http://www.w3.org/2001/XMLSchema"
        ), type.attribute('name').to_s)
      end

      @document.xpath(
        "s0:definitions/s0:types/xs:schema/xs:complexType[@name]",
        "s0" => "http://schemas.xmlsoap.org/wsdl/",
        "xs" => "http://www.w3.org/2001/XMLSchema"
      ).each do |type|
        process_type(type, type.attribute('name').to_s)
      end
    end

    def process_type(type, name)
      return unless type
      @types[name] ||= { :namespace => find_namespace(type) }

      type.xpath("./xs:sequence/xs:element",
        "xs" => "http://www.w3.org/2001/XMLSchema"
      ).each do |inner_element|
        @types[name][inner_element.attribute('name').to_s] = {
          :type => inner_element.attribute('type').to_s
        }
      end
    end

    def find_namespace(type)
      schema_namespace = type.at_xpath("ancestor::xs:schema/@targetNamespace",
        "xs" => "http://www.w3.org/2001/XMLSchema"
      )
      schema_namespace ? schema_namespace.to_s : @namespace
    end

  end
end
