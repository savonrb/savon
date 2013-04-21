require "nokogiri"
require "wasabi/resolver"
require "wasabi/parser"

module Wasabi

  # = Wasabi::Document
  #
  # Represents a WSDL document.
  class Document

    ELEMENT_FORM_DEFAULTS = [:unqualified, :qualified]

    # Validates if a given +value+ is a valid elementFormDefault value.
    # Raises an +ArgumentError+ if the value is not valid.
    def self.validate_element_form_default!(value)
      return if ELEMENT_FORM_DEFAULTS.include?(value)

      raise ArgumentError, "Invalid value for elementFormDefault: #{value}\n" +
                           "Must be one of: #{ELEMENT_FORM_DEFAULTS.inspect}"
    end

    # Accepts a WSDL +document+ to parse.
    def initialize(document = nil)
      self.document = document
    end

    attr_accessor :document, :request, :xml

    alias_method :document?, :document

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
      @element_form_default ||= document ? parser.element_form_default : :unqualified
    end

    # Sets the elementFormDefault value.
    def element_form_default=(value)
      self.class.validate_element_form_default!(value)
      @element_form_default = value
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

    # Returns the service name.
    def service_name
      @service_name ||= parser.service_name
    end

    attr_writer :service_name

    def type_namespaces
      @type_namespaces ||= begin
        namespaces = []
        parser.types.each do |type, info|
          namespaces << [[type], info[:namespace]]
          (info.keys - [:namespace]).each { |field| namespaces << [[type, field], info[:namespace]] }
        end if document
        namespaces
      end
    end

    def type_definitions
      @type_definitions ||= begin
        result = []
        parser.types.each do |type, info|
          (info.keys - [:namespace]).each do |field|
            field_type = info[field][:type]
            tag, namespace = field_type.split(":").reverse
            result << [[type, field], tag] if user_defined(namespace)
          end
        end if document
        result
      end
    end

    # Returns whether the given +namespace+ was defined manually.
    def user_defined(namespace)
      uri = parser.namespaces[namespace]
      !(uri =~ %r{^http://schemas.xmlsoap.org} || uri =~ %r{^http://www.w3.org})
    end

    # Returns the raw WSDL document.
    # Can be used as a hook to extend the library.
    def xml
      @xml ||= Resolver.new(document, request).resolve
    end

    # Parses the WSDL document and returns the <tt>Wasabi::Parser</tt>.
    def parser
      @parser ||= guard_parse && parse
    end

  private

    # Raises an error if the WSDL document is missing.
    def guard_parse
      return true if document
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
