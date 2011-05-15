require "nokogiri"

require "savon/wsdl/request"
require "savon/wsdl/parser"

module Savon
  module WSDL

    # = Savon::WSDL::Document
    #
    # Represents the WSDL of your service, including information like the namespace URI,
    # the SOAP endpoint and available SOAP actions.
    class Document

      # Accepts an <tt>HTTPI::Request</tt> and a +document+.
      def initialize(request = nil, document = nil)
        self.request = request
        self.document = document
      end

      # Accessor for the <tt>HTTPI::Request</tt> to use.
      attr_accessor :request

      def present?
        !!@document
      end

      # Returns the namespace URI of the WSDL.
      def namespace
        @namespace ||= parser.namespace
      end

      def type_namespaces
        namespaces = []
        parser.types.each do |type, info|
          namespaces << [[type], info[:namespace]]
          (info.keys - [:namespace]).each do |field|
            namespaces << [[type, field], info[:namespace]]
          end
        end if present?
        namespaces
      end
      
      def type_definitions
        return [] if !present?

        result = []
        parser.types.each do |type, info|
          (info.keys - [:namespace]).each do |field|
            field_type = info[field][:type]
            tag, namespace = field_type.split(":").reverse
            result << [[type, field], tag] if user_defined(namespace)
          end
        end
        result
      end
      
      def user_defined(namespace_identifier)
        uri = parser.namespaces[namespace_identifier]
        !(uri =~ %r{^http://schemas.xmlsoap.org} ||
          uri =~ %r{^http://www.w3.org})
      end

      # Sets the SOAP namespace.
      attr_writer :namespace

      # Returns the SOAP endpoint.
      def endpoint
        @endpoint ||= parser.endpoint
      end

      # Sets the SOAP endpoint.
      attr_writer :endpoint

      # Returns an Array of available SOAP actions.
      def soap_actions
        @soap_actions ||= parser.operations.keys
      end

      # Returns the SOAP action for a given +key+.
      def soap_action(key)
        operations[key][:action] if present? && operations[key]
      end

      # Returns the SOAP input for a given +key+.
      def soap_input(key)
        operations[key][:input].to_sym if present? && operations[key]
      end

      # Returns a Hash of SOAP operations.
      def operations
        @operations ||= parser.operations
      end

      # Returns the elementFormDefault value.
      def element_form_default
        @element_form_default ||= parser.element_form_default
      end

      # Sets the location of the WSDL document to use. This can either be a URL
      # or a path to a local file.
      attr_writer :document

      # Returns the raw WSDL document.
      def document
        @wsdl_document ||= begin
          raise ArgumentError, "No WSDL document given" if @document.blank?
          remote? ? http_request : read_file
        end
      end

      alias :to_xml :document

    private

      # Returns whether the WSDL document is located on the Web.
      def remote?
        @document =~ /^http/
      end

      # Executes an HTTP GET request to retrieve a remote WSDL document.
      def http_request
        request.url = @document
        Request.execute(request).body
      end

      # Reads the WSDL document from a local file.
      def read_file
        File.read @document
      end

      # Parses the WSDL document and returns the <tt>Savon::WSDL::Parser</tt>.
      def parser
        @parser ||= begin
          parser = Parser.new(Nokogiri::XML(document))
          parser.parse
          parser
        end
      end

    end
  end
end
