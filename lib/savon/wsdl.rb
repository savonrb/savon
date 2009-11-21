require "rexml/document"

module Savon

  # Savon::WSDL
  #
  # Savon::WSDL represents the WSDL document of a SOAP service. The WSDL
  # contains information about available SOAP actions and serves as a more
  # or less qualitative API documentation.
  class WSDL
    include HTTP

    # Initializer expects the WSDL +endpoint+ URI.
    def initialize(endpoint)
      @endpoint = endpoint
    end

    # Returns the namespace URI from the WSDL.
    def namespace_uri
      @namespace_uri ||= parse_namespace_uri
    end

    # Returns an Array of available SOAP actions from the WSDL.
    def soap_actions
      map_soap_actions.keys
    end

    # Returns the original SOAP action name for a given +method+ name.
    # Defaults to +nil+ in case no SOAP action name could be found.
    def soap_action_for(method)
      map_soap_actions[method]
    end

    # Returns the WSDL or +nil+ in case the WSDL could not be retrieved.
    def to_s
      wsdl_response ? wsdl_response.body : nil
    end

  private

    # Retrieves and returns the WSDL.
    # Raises an ArgumentError in case the WSDL seems to be invalid. 
    def wsdl_response
      unless @wsdl_response
        @wsdl_response = http_get_wsdl
        #raise ArgumentError, "Invalid WSDL at: #{@endpoint}" #unless valid_wsdl?
      end
      @wsdl_response
    end

    # Returns an Hpricot::Document of the WSDL.
    def wsdl_document
      @wsdl_document ||= REXML::Document.new wsdl_response.body
    end

    # Returns whether the WSDL seems to be valid.
    def valid_wsdl?
      soap_actions && !soap_actions.empty?
    end

    # Parses the WSDL for the namespace URI.
    def parse_namespace_uri
      definitions = wsdl_document.elements["//wsdl:definitions"]
      definitions.attributes["targetNamespace"] if definitions
    end

    # Parses the WSDL for available SOAP actions.
    def parse_soap_actions
      wsdl_document.elements.collect "//[@soapAction]" do |element|
        element.parent.attributes["name"]
      end
    end

    # Takes an Array of +soap_actions+ and returns a Hash containing the SOAP
    # actions converted to snake_case (keys) and their original names (values). 
    def map_soap_actions
      @soap_action_map ||= parse_soap_actions.inject({}) do |hash, soap_action|
        hash.merge soap_action.snakecase.to_sym => soap_action
      end
    end

  end
end
