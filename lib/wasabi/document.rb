require "nokogiri"
require "wasabi/resolver"
require "wasabi/parser"

class Wasabi

  # = Wasabi::Document
  #
  # Represents a WSDL document.
  class Document

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
    def target_namespace
      @target_namespace ||= parser.target_namespace
    end

    # Sets the target namespace.
    attr_writer :target_namespace

    # Returns a list of available SOAP actions.
    def soap_actions
      @soap_actions ||= parser.operations.keys
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

    def namespaces
      parser.namespaces
    end

    # XXX: legacy interface. change savon to use the new types interface.
    def type_namespaces
      @type_namespaces ||= begin
        namespaces = []
        parser.schemas.types.each do |name, type|
          namespaces << [[name], type.namespace]
          type.children.each { |child| namespaces << [[name, child[:name]], type.namespace] }
        end if document
        namespaces
      end
    end

    # XXX: legacy interface. change savon to use the new types interface.
    def type_definitions
      @type_definitions ||= begin
        result = []
        parser.schemas.types.each do |name, type|
          type.children.each do |child|
            # how can we properly handle anyType elements here?
            # see Type#parse_element
            next unless child[:type]

            tag, nsid = child[:type].split(":").reverse
            result << [[name, child[:name]], tag] if user_defined(nsid)
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

    def parser
      @parser ||= guard_parse && parse
    end

  private

    def guard_parse
      return true if document
      raise ArgumentError, "Wasabi needs a WSDL document"
    end

    def parse
      Parser.new Nokogiri::XML(xml)
    end

  end
end
