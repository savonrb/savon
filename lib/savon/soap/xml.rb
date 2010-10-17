require "builder"
require "crack/xml"
require "savon/soap"
require "savon/core_ext/hash"

module Savon
  module SOAP

    # = Savon::SOAP::XML
    #
    # Represents the SOAP request XML. Contains various global and per request/instance settings
    # like the SOAP version, header, body and namespaces.
    class XML

      # XML Schema Type namespaces.
      SchemaTypes = {
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
      }

      def self.to_hash(xml)
        (Crack::XML.parse(xml) rescue {}).find_soap_body
      end

      # Accepts an +endpoint+, an +input+ tag and a SOAP +body+.
      def initialize(endpoint = nil, input = nil, body = nil)
        self.endpoint = endpoint if endpoint
        self.input = input if input
        self.body = body if body
      end

      # Accessor for the SOAP +input+ tag.
      attr_accessor :input

      # Accessor for the SOAP +endpoint+.
      attr_accessor :endpoint

      # Sets the SOAP +version+.
      def version=(version)
        raise ArgumentError, "Invalid SOAP version: #{version}" unless SOAP::Versions.include? version
        @version = version
      end

      # Returns the SOAP +version+. Defaults to <tt>Savon.soap_version</tt>.
      def version
        @version ||= Savon.soap_version
      end

      # Sets the SOAP +header+ Hash.
      attr_writer :header

      # Returns the SOAP +header+. Defaults to an empty Hash.
      def header
        @header ||= {}
      end

      # Sets the +namespaces+ Hash.
      attr_writer :namespaces

      # Returns the +namespaces+. Defaults to a Hash containing the <tt>xmlns:env</tt> namespace.
      def namespaces
        @namespaces ||= { "xmlns:env" => SOAP::Namespace[version] }
      end

      # Sets the default namespace identifier.
      attr_writer :namespace_identifier

      # Returns the default namespace identifier.
      def namespace_identifier
        @namespace_identifier ||= :wsdl
      end

      # Accessor for the default namespace URI.
      attr_accessor :namespace

      # Accessor for the <tt>Savon::WSSE</tt> object.
      attr_accessor :wsse

      # Accessor for the SOAP +body+. Expected to be a Hash that can be translated to XML via Hash.to_soap_xml
      # or any other Object responding to to_s.
      attr_accessor :body

      # Accepts a +block+ and yields a <tt>Builder::XmlMarkup</tt> object to let you create custom XML.
      def xml
        @xml = yield builder if block_given?
      end

      # Accepts an XML String and lets you specify a completely custom request body.
      attr_writer :xml

      # Returns the XML for a SOAP request.
      def to_xml
        @xml ||= builder.env :Envelope, complete_namespaces do |xml|
          xml.env(:Header) { xml << header_for_xml } unless header_for_xml.empty?
          xml.env(:Body) { xml.tag!(*input) { xml << body_to_xml } }
        end
      end

    private

      # Returns a new <tt>Builder::XmlMarkup</tt> object.
      def builder
        builder = Builder::XmlMarkup.new
        builder.instruct!
        builder
      end

      # Returns the complete Hash of namespaces.
      def complete_namespaces
        defaults = SchemaTypes.dup
        defaults["xmlns:#{namespace_identifier}"] = namespace if namespace
        defaults.merge namespaces
      end

      # Returns the SOAP header as an XML String.
      def header_for_xml
        header.to_soap_xml + wsse_header
      end

      # Returns the WSSE header or an empty String in case WSSE was not set.
      def wsse_header
        wsse.respond_to?(:to_xml) ? wsse.to_xml : ""
      end

      # Returns the SOAP body as an XML String.
      def body_to_xml
        body.respond_to?(:to_soap_xml) ? body.to_soap_xml : body.to_s
      end

    end
  end
end
