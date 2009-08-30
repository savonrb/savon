%w(rubygems net/http hpricot).each do |gem|
  require gem
end

module Savon

  # Savon::Wsdl represents the WSDL document.
  class Wsdl

    # Namespace URI found in the WSDL.
    attr_reader :namespace_uri

    # SOAP service methods found in the WSDL.
    attr_reader :service_methods

    # Choice elements found in the WSDL.
    attr_reader :choice_elements

    # Initializer expects an endpoint +uri+ and an +http+ connection instance,
    # then gets and parses the WSDL at the given URI.
    def initialize(uri, http)
      @uri, @http = uri, http
      get_wsdl

      parse_namespace_uri
      parse_service_methods
      parse_choice_elements
    end

    # Returns the response body from the WSDL request.
    def to_s
      @response.body
    end

  private

    # Gets the WSDL from the specified URI.
    def get_wsdl
      @response = @http.get("#{@uri.path}?#{@uri.query}")
      @doc = Hpricot.XML(@response.body)

      if !@doc.at("//wsdl:definitions")
        raise ArgumentError, "Unable to find WSDL at given endpoint URI."
      end
    end

    # Parses the WSDL for the namespace URI.
    def parse_namespace_uri
      node = @doc.at("//wsdl:definitions")
      @namespace_uri = node.get_attribute("targetNamespace") if node
    end

    # Parses the WSDL for available SOAP service methods.
    def parse_service_methods
      @service_methods = []
      node = @doc.search("//soap:operation")

      node.each do |operation|
        service_methods << operation.parent.get_attribute("name")
      end if node
    end

    # Parses the WSDL for choice elements.
    def parse_choice_elements
      @choice_elements = []
      node = @doc.search("//xs:choice//xs:element")

      node.each do |choice|
        name = choice.get_attribute("ref").sub(/(.+):/, "")
        choice_elements << name unless @choice_elements.include?(name)
      end if node
    end

  end
end