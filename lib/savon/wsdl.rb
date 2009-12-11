module Savon

  # Savon::WSDL
  #
  # Represents a WSDL document.
  class WSDL

    # Expects a Savon::Request object.
    def initialize(request)
      @request = request
    end

    # Returns the namespace URI from the WSDL.
    def namespace_uri
      @namespace_uri ||= document.root.attributes["targetNamespace"] || ""
    end

    # Returns a Hash of available SOAP actions mapped to snake_case (keys)
    # and their original names and inputs in another Hash (values).
    def soap_actions
      @soap_actions ||= parse_soap_operations.inject({}) do |hash, (input, action)|
        hash.merge input.snakecase.to_sym => { :name => action, :input => input }
      end
    end

    # Returns +true+ for available methods and SOAP actions.
    def respond_to?(method)
      return true if soap_actions.keys.include? method
      super
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
        raise ArgumentError, "Invalid WSDL: #{@request.endpoint}" if soap_actions.empty?
      end
      @wsdl_response
    end

    # Returns a REXML::Document of the WSDL.
    def document
      @document ||= REXML::Document.new wsdl_response.body
    end

    # Parses the WSDL for available SOAP actions and inputs. Returns a Hash
    # containing the SOAP action inputs and corresponding SOAP actions.
    def parse_soap_operations
      wsdl_binding = document.elements["wsdl:definitions/wsdl:binding"]
      return {} unless wsdl_binding

      wsdl_binding.elements.inject("wsdl:operation", {}) do |hash, operation|
        action = operation.elements["*:operation"].attributes["soapAction"] || ""
        action = operation.attributes["name"] if action.empty?

        hash.merge action.split("/").last => action
      end
    end

  end
end
