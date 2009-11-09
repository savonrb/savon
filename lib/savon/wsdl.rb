require 'rubygems'
require 'hpricot'

module Savon

  # Savon::WSDL represents the WSDL document.
  class WSDL

    # Initializer expects instances of Savon::Options and Savon::HTTP.
    def initialize(options, http)
      @options, @http = options, http
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

    # Returns the body of the Net::HTTPResponse from the WSDL request.
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

      soap_actions.collect do |soap_action|
        soap_action.parent.get_attribute('name')
      end if soap_actions
    end

    # Parses the WSDL for choice elements.
    def parse_choice_elements
      choice_elements = wsdl_document.search('//xs:choice//xs:element')

      choice_elements.collect do |choice_element|
        choice_element.get_attribute('ref').sub(/(.+):/, '')
      end if choice_elements
    end

  end
end
