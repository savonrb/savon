require "rubygems"
require "net/http"
require "hpricot"

module Savon

  # Savon::Wsdl gets, parses and represents the SOAP-WSDL.
  class Wsdl

    # The namespace URI.
    attr_reader :namespace_uri

    # SOAP service methods.
    attr_reader :service_methods

    # Choice elements.
    attr_reader :choice_elements

    # Initializer expects an endpoint +uri+ and an +http+ connection instance,
    # then gets and parses the WSDL at the given URI.
    #
    # === Parameters
    #
    # * +uri+ - The URI to access.
    # * +http+ - The Net::HTTP connection instance to use.
    def initialize(uri, http)
      @uri = uri
      @http = http
      get_wsdl
      parse_wsdl
    end

    # Returns the response body from the WSDL request.
    def to_s
      @response.body
    end

  private

    # Gets the WSDL at the given URI.
    def get_wsdl
      @response = @http.get("#{@uri.path}?#{@uri.query}")
      @doc = Hpricot.XML(@response.body)
    end

    # Parses the WSDL for the namespace URI, available service methods
    # and choice elements.
    def parse_wsdl
      @namespace_uri = @doc.at("//wsdl:definitions").get_attribute("targetNamespace")

      @service_methods = []
      @doc.search("//soap:operation").each do |operation|
        service_methods << operation.parent.get_attribute("name")
      end

      @choice_elements = []
      @doc.search("//xs:choice//xs:element").each do |choice|
        name = choice.get_attribute("ref").sub(/(.+):/, "")
        choice_elements << name unless @choice_elements.include? name
      end
    end

  end
end