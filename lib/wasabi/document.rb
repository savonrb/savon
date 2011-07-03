require "nokogiri"
require "wasabi/parser"

module Wasabi

  # = Wasabi::Document
  #
  # Represents a WSDL document.
  class Document

    # Accepts a WSDL +document+ to parse.
    def initialize(document = nil)
      self.document = document
    end

    attr_accessor :document

    # Returns whether a +document+ was set.
    def document?
      !!document
    end

    # Returns the SOAP endpoint.
    def endpoint
      @endpoint ||= parser.endpoint
    end

    # Sets the SOAP endpoint.
    attr_writer :endpoint

    # Returns the target namespace.
    def namespace
      @namespace ||= parser.namespace
    end

    # Sets the target namespace.
    attr_writer :namespace

    # Returns the value of elementFormDefault.
    def element_form_default
      @element_form_default ||= parser.element_form_default
    end

    # Returns a list of available SOAP actions.
    def soap_actions
      @soap_actions ||= parser.operations.keys
    end

    # Returns the SOAP action for a given +key+.
    def soap_action(key)
      operations[key][:action] if operations[key]
    end

    # Returns the SOAP input for a given +key+.
    def soap_input(key)
      operations[key][:input] if operations[key]
    end

    # Returns a map of SOAP operations.
    def operations
      @operations ||= parser.operations
    end

    # Returns the raw WSDL document.
    # Can be used as a hook to extend the library.
    def xml
      @xml ||= document
    end

  private

    # Parses the WSDL document and returns the <tt>Wasabi::Parser</tt>.
    def parser
      @parser ||= guard_parse && parse
    end

    # Raises an error if the WSDL document is missing.
    def guard_parse
      return true if xml.kind_of?(String)
      raise ArgumentError, "Wasabi needs a WSDL document"
    end

    # Parses the WSDL document and returns <tt>Wasabi::Parser</tt>.
    def parse
      parser = Parser.new Nokogiri::XML(xml)
      parser.parse
      parser
    end

  end
end
