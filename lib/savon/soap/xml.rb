require "builder"
require "crack/xml"
require "gyoku"

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

      # Converts the given SOAP response +value+ (XML or Hash) into a normalized Hash.
      def self.to_hash(value)
        value = parse value unless value.kind_of? Hash
        value.find_soap_body
      end

      # Converts a given SOAP response +xml+ to a Hash.
      def self.parse(xml)
        Crack::XML.parse(xml)
      end

      # Expects a SOAP response XML or Hash, traverses it for a given +path+ of Hash keys
      # and returns the value as an Array. Defaults to return an empty Array in case the
      # path does not exist or returns nil.
      def self.to_array(object, *path)
        hash = object.kind_of?(Hash) ? object : to_hash(object)

        result = path.inject hash do |memo, key|
          return [] unless memo[key]
          memo[key]
        end

        result.kind_of?(Array) ? result.compact : [result].compact
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
      
      def namespace_by_uri(uri)
        namespaces.each do |candidate_identifier, candidate_uri|
          return candidate_identifier.gsub(/^xmlns:/, '') if candidate_uri == uri
        end
        return nil
      end

      def used_namespaces
        @used_namespaces ||= {}
      end

      def use_namespace(path, uri)
        @internal_namespace_count ||= 0
        
        identifier = namespace_by_uri(uri)
        if !identifier
          identifier = "ins#{@internal_namespace_count}"
          namespaces["xmlns:#{identifier}"] = uri
          @internal_namespace_count += 1
        end

        used_namespaces[path] = identifier
      end
      
      def types
        @types ||= {}
      end
      
      def define_type(path, type)
        types[path] = type
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
          if input.nil?
            tag(xml, :Body)
          else
            tag(xml, :Body) {
              xml.tag!(*add_namespace_to_input) { xml << body_to_xml }
            }
          end
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
        Gyoku.xml add_namespaces(body), :element_form_default => element_form_default, :namespace => namespace_identifier
      end

      def add_namespaces(hash, path = [input.to_s])
        return hash.to_s unless hash.kind_of? Hash
        hash.inject({}) do |newhash, (key, value)|
          newpath = path + [key.to_s]
          
          if used_namespaces[newpath]
            newhash.merge(
              "#{used_namespaces[newpath]}:#{key.to_s}" =>
                add_namespaces(value,
                  types[newpath] ? [types[newpath]] : newpath))
          else
            newhash.merge(key => value)
          end
        end
      end

      def add_namespace_to_input
        namespace, tag, attributes = nil, nil, nil
        if Array === input && input.length == 3
          namespace, tag, attributes = input
        elsif Array === input && input.length == 2
          tag, attributes = input
        else
          tag = input
        end

        if used_namespaces[[tag.to_s]]
          [used_namespaces[[tag.to_s]], tag, attributes]
        else
          input
        end
      end

    end
  end
end

