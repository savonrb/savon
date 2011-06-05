require "builder"
require "gyoku"
require "nori"

require "savon/soap"

Nori.configure do |config|
  config.strip_namespaces = true
  config.convert_tags_to { |tag| tag.snakecase.to_sym }
end

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
        @header ||= Savon.soap_header.nil? ? {} : Savon.soap_header
      end

      # Sets the SOAP envelope namespace.
      attr_writer :env_namespace

      # Returns the SOAP envelope namespace. Uses the global namespace if set Defaults to :env.
      def env_namespace
        @env_namespace ||= Savon.env_namespace.nil? ? :env : Savon.env_namespace
      end

      # Sets the +namespaces+ Hash.
      attr_writer :namespaces

      # Returns the +namespaces+. Defaults to a Hash containing the SOAP envelope namespace.
      def namespaces
        @namespaces ||= begin
          key = env_namespace.blank? ? "xmlns" : "xmlns:#{env_namespace}"
          { key => SOAP::Namespace[version] }
        end
      end

      # Sets the default namespace identifier.
      attr_writer :namespace_identifier

      # Returns the default namespace identifier.
      def namespace_identifier
        @namespace_identifier ||= :wsdl
      end

      # Returns whether all local elements should be namespaced. Might be set to :qualified,
      # but defaults to :unqualified.
      def element_form_default
        @element_form_default ||= :unqualified
      end

      # Sets whether all local elements should be namespaced.
      attr_writer :element_form_default

      # Accessor for the default namespace URI.
      attr_accessor :namespace

      # Accessor for the <tt>Savon::WSSE</tt> object.
      attr_accessor :wsse

      # Accessor for the SOAP +body+. Expected to be a Hash that can be translated to XML via Gyoku.xml
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
        @xml ||= tag(builder, :Envelope, complete_namespaces) do |xml|
          tag(xml, :Header) { xml << header_for_xml } unless header_for_xml.empty?
          input.nil? ? tag(xml, :Body) : tag(xml, :Body) { xml.tag!(*input) { xml << body_to_xml } }
        end
      end

    private

      # Returns a new <tt>Builder::XmlMarkup</tt> object.
      def builder
        builder = Builder::XmlMarkup.new
        builder.instruct!
        builder
      end

      # Expects a builder +xml+ instance, a tag +name+ and accepts optional +namespaces+
      # and a block to create an XML tag.
      def tag(xml, name, namespaces = {}, &block)
        return xml.tag! name, namespaces, &block if env_namespace.blank?
        xml.tag! env_namespace, name, namespaces, &block
      end

      # Returns the complete Hash of namespaces.
      def complete_namespaces
        defaults = SchemaTypes.dup
        defaults["xmlns:#{namespace_identifier}"] = namespace if namespace
        defaults.merge namespaces
      end

      # Returns the SOAP header as an XML String.
      def header_for_xml
        @header_for_xml ||= Gyoku.xml(header) + wsse_header
      end

      # Returns the WSSE header or an empty String in case WSSE was not set.
      def wsse_header
        wsse.respond_to?(:to_xml) ? wsse.to_xml : ""
      end

      # Returns the SOAP body as an XML String.
      def body_to_xml
        return body.to_s unless body.kind_of? Hash
        Gyoku.xml body, :element_form_default => element_form_default, :namespace => namespace_identifier
      end

    end
  end
end
