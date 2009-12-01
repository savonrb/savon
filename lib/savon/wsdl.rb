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
      soap_action_map.keys
    end

    # Returns a Hash of available SOAP actions mapped to snake_case (keys)
    # and their original names and inputs in another Hash (values).
    def soap_action_map
      @soap_action_map ||= parse_soap_operations.inject({}) do |hash, (input, action)|
        hash.merge input.snakecase.to_sym => { :name => action, :input => input }
      end
    end

    # Returns the WSDL document.
    def to_s
      wsdl_response.body
    end

  private

    # Retrieves and returns the WSDL response. Raises an ArgumentError in
    # case the WSDL seems to be invalid. 
    def wsdl_response
      unless @wsdl_response
        @wsdl_response ||= @request.wsdl
        invalid! :wsdl, @request.endpoint if soap_actions.empty?
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

    # Parses the WSDL for available SOAP actions and inputs. Returns a Hash
    # containing the SOAP action inputs and corresponding SOAP actions.
    def parse_soap_operations
      document.elements.inject("//soap:operation", {}) do |hash, operation|
        action = operation.attributes["soapAction"] || ""
        action = operation.parent.attributes["name"] if action.empty?

        hash.merge action.split("/").last => action
      end
    end

  end
end
