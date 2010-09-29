require "builder"
require "savon/soap"
require "savon/core_ext/hash"

module Savon
  module SOAP

    # = Savon::SOAP::XML
    #
    # Represents the SOAP request XML. Contains various global and per request/instance settings
    # like the SOAP version, header, body and namespaces.
    class XML

      class << self

        # Sets the global SOAP +header+ Hash.
        attr_writer :header

        # Returns the global SOAP header. Defaults to an empty Hash.
        def header
          @header ||= {}
        end

        # Sets the global +namespaces+ Hash.
        attr_writer :namespaces

        # Returns the global +namespaces+. Defaultsto an empty Hash.
        def namespaces
          @namespaces ||= {}
        end

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

      # Returns the SOAP +version+. Defaults to the global default.
      def version
        @version ||= SOAP.version
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

      # Convenience method for setting the <tt>xmlns:wsdl</tt> namespace.
      def namespace=(namespace)
        namespaces["xmlns:wsdl"] = namespace
      end

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
        @xml ||= builder.env :Envelope, namespaces_for_xml do |xml|
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

      # Returns the SOAP header as an XML String.
      def header_for_xml
        @xml_header ||= (self.class.header.merge(header)).to_soap_xml + wsse_header
      end

      # Returns the WSSE header or an empty String in case WSSE was not set.
      def wsse_header
        wsse.respond_to?(:to_xml) ? wsse.to_xml : ""
      end

      # Returns the SOAP body as an XML String.
      def body_to_xml
        body.respond_to?(:to_soap_xml) ? body.to_soap_xml : body.to_s
      end

      # Returns the Hash of namespaces for the SOAP envelope.
      def namespaces_for_xml
        self.class.namespaces.merge namespaces
      end

    end
  end
end
