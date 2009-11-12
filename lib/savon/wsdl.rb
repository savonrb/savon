require 'rubygems'
require 'hpricot'

module Savon

  # Savon::WSDL represents the WSDL document.
  class WSDL

    # Initializer expects instances of Savon::HTTP and Savon::Options.
    def initialize(http, options)
      @http = http
      @options = options
    end

    # Returns the namespace URI.
    def namespace_uri
      @namespace ||= parse_namespace_uri
    end

    # Returns an Array of available SOAP actions.
    def soap_actions
      @soap_actions ||= parse_soap_actions
    end

    # Returns an Array of choice elements.
    def choice_elements
      @choice_elements ||= parse_choice_elements
    end

    # Returns the lowerCamelCase or CamelCase name of a SOAP action for a given
    # +string+. The string may be either lowerCamelCase, CamelCase or snake_case.
    def soap_action_for(string)
      mapped_soap_actions[Inflector.snake_case string]
    end

    # Returns the body of the Net::HTTPResponse from the WSDL request.
    # Defaults to +nil+ in case of a missing or invalid WSDL.
    def to_s
      wsdl_response ? wsdl_response.body : nil
    end

  private

    def wsdl_response
      unless @wsdl_response
        @wsdl_response = @http.retrieve_wsdl
        validate_wsdl!
      end
      @wsdl_response
    end

    # Returns an Hpricot::Document of the WSDL. Retrieves the WSDL from the
    # endpoint URI in case it wasn't retrieved already.
    def wsdl_document
      @wsdl_document = Hpricot.XML(wsdl_response.body) unless @wsdl_document
      @wsdl_document
    end

    def validate_wsdl!
      if !soap_actions || soap_actions.empty?
        raise ArgumentError, "Unable to find WSDL at: #{@options.endpoint}"
      end
    end

    # Parses the WSDL for the namespace URI.
    def parse_namespace_uri
      definitions = wsdl_document.at('//wsdl:definitions')
      definitions.get_attribute('targetNamespace') if definitions
    end

    # Parses the WSDL for available SOAP actions.
    def parse_soap_actions
      soap_actions = wsdl_document.search('[@soapAction]')

      return [] unless soap_actions
      soap_actions.collect do |soap_action|
        soap_action.parent.get_attribute('name')
      end
    end

    # Parses the WSDL for choice elements.
    def parse_choice_elements
      choice_elements = wsdl_document.search('//xs:choice//xs:element')

      return [] unless choice_elements
      choice_elements.collect do |choice_element|
        choice_element.get_attribute('ref').sub(/(.+):/, '')
      end
    end

    # Returns a Hash containing all available SOAP actions with keys containing
    # the name of the SOAP action converted to snake_case and the values containing
    # the original name of the SOAP action (probably lowerCamelCase/CamelCase).
    def mapped_soap_actions
      @mapped_soap_actions ||= soap_actions.inject({}) do |hash, soap_action|
        hash.merge Inflector.snake_case(soap_action) => soap_action
      end
    end

  end
end
