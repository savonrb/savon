module Savon

  # Savon::WSDL represents the WSDL document.
  class WSDL

    # @return [String] Namespace URI of the WSDL.
    def namespace_uri
      @namespace ||= parse_namespace_uri
    end

    # @return [Array] SOAP service methods of the WSDL.
    def soap_actions
      @soap_actions ||= parse_soap_actions
    end

    # @return [Array] Choice elements of the WSDL.
    def choice_elements
      @choice_elements ||= parse_choice_elements
    end

    # Initializer expects an instance of Savon::HTTP to retrieve the WSDL.
    #
    # ==== Parameters
    # * <tt>http</tt> - [Net::HTTP] Net::HTTP instance to retrieve the WSDL
    def initialize(uri, http)
      @uri, @http = uri, http
    end

    # Returns the body of the Net::HTTPResponse from the WSDL request.
    def to_s
      @response ? @response.body : nil
    end

  private

    def document
      unless @document
        @response = @http.get("#{@uri.path}?#{@uri.query}")
        @document = Hpricot.XML(@response.body)
        raise ArgumentError, "Unable to find WSDL at: #{@uri}" if
          !soap_actions || soap_actions.empty?
      end
      @document
    end

    # Parses the WSDL for the namespace URI.
    def parse_namespace_uri
      definitions = document.at("//wsdl:definitions")
      definitions.get_attribute("targetNamespace") if definitions
    end

    # Parses the WSDL for available SOAP service methods.
    def parse_soap_actions
      soap_actions = document.search("//soap:operation")

      soap_actions.collect do |soap_action|
        soap_action.parent.get_attribute("name")
      end if soap_actions
    end

    # Parses the WSDL for choice elements.
    def parse_choice_elements
      choice_elements = document.search("//xs:choice//xs:element")

      choice_elements.collect do |choice_element|
        choice_element.get_attribute("ref").sub(/(.+):/, "")
      end if choice_elements
    end

  end
end
