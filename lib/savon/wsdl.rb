module Savon

  # Savon::WSDL
  #
  # Savon::WSDL represents a WSDL document. A WSDL document serves as a more
  # or less qualitative API documentation.
  class WSDL
    include Validation

    # Expects a Savon::Request object.
    def initialize(request)
      @request = request
    end

    # Returns the namespace URI from the WSDL.
    def namespace_uri
      @namespace_uri ||= parse_namespace_uri
    end

    # Returns an Array of available SOAP actions from the WSDL.
    def soap_actions
      mapped_soap_actions.keys
    end

    # Returns a Hash of available SOAP actions and their original names.
    def mapped_soap_actions
      @mapped_soap_actions ||= parse_soap_actions.inject Hash.new do |hash, soap_action|
        hash.merge soap_action.snakecase.to_sym => soap_action
      end
    end

    # Returns the WSDL or +nil+ in case the WSDL could not be retrieved.
    def to_s
      wsdl_response ? wsdl_response.body : nil
    end

  private

    # Retrieves and returns the WSDL response. Raises an ArgumentError in
    # case the WSDL seems to be invalid. 
    def wsdl_response
      unless @wsdl_response
        @wsdl_response ||= @request.wsdl
        invalid! :wsdl, @request.endpoint unless soap_actions && !soap_actions.empty?
      end
      @wsdl_response
    end

    # Returns a REXML::Document of the WSDL.
    def document
      @document ||= REXML::Document.new wsdl_response.body
    end

    # Parses the WSDL for the namespace URI.
    def parse_namespace_uri
      definitions = document.elements["//wsdl:definitions"]
      definitions.attributes["targetNamespace"] if definitions
    end

    # Parses the WSDL for available SOAP actions.
    def parse_soap_actions
      document.elements.collect "//[@soapAction]" do |element|
        element.parent.attributes["name"]
      end
    end

  end
end