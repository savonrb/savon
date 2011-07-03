require "uri"
require "wasabi/core_ext/string"

module Wasabi

  # = Wasabi::Parser
  #
  # Parses WSDL documents and remembers their important parts.
  class Parser

    def initialize(document)
      @document = document
      @path = []
      @operations = {}
      @namespaces = {}
      @element_form_default = :unqualified
    end

    # Returns the SOAP endpoint.
    attr_reader :endpoint

    # Returns the target namespace.
    attr_reader :namespace

    # Returns the SOAP operations.
    attr_reader :operations

    # Returns the value of elementFormDefault.
    attr_reader :element_form_default

    def parse
      parse_namespaces
      parse_endpoint
      parse_operations
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

          action = soap_action && !soap_action.empty? ? soap_action : name
          input = (!name || name.empty?) ? action.split("/").last : name

          @operations[input.snakecase.to_sym] =
            { :action => action, :input => input }
        elsif !@operations[name.snakecase.to_sym]
          @operations[name.snakecase.to_sym] =
            { :action => name, :input => name }
        end
      end
    end

  end
end
