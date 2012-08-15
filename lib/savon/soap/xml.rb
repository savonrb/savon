require "builder"
require "gyoku"
require "rexml/document"
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
      SCHEMA_TYPES = {
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
      }

      # Expects a +config+ object.
      def initialize(config)
        self.config = config
      end

      attr_accessor :config

      # Accessor for the SOAP +input+ tag.
      attr_accessor :input

      # Accessor for the SOAP +endpoint+.
      attr_accessor :endpoint

      # Sets the SOAP +version+.
      def version=(version)
        raise ArgumentError, "Invalid SOAP version: #{version}" unless SOAP::VERSIONS.include? version
        @version = version
      end

      # Returns the SOAP +version+. Defaults to <tt>Savon.config.soap_version</tt>.
      def version
        @version ||= config.soap_version
      end

      # Sets the SOAP +header+ Hash.
      attr_writer :header

      # Returns the SOAP +header+. Defaults to an empty Hash.
      def header
        @header ||= config.soap_header.nil? ? {} : config.soap_header
      end

      # Sets the SOAP envelope namespace.
      attr_writer :env_namespace

      # Returns the SOAP envelope namespace. Uses the global namespace if set Defaults to :env.
      def env_namespace
        @env_namespace ||= config.env_namespace.nil? ? :env : config.env_namespace
      end

      # Sets the +namespaces+ Hash.
      attr_writer :namespaces

      # Returns the +namespaces+. Defaults to a Hash containing the SOAP envelope namespace.
      def namespaces
        @namespaces ||= begin
          key = ["xmlns"]
          key << env_namespace if env_namespace && env_namespace != ""
          { key.join(":") => SOAP::NAMESPACE[version] }
        end
      end

      def namespace_by_uri(uri)
        namespaces.each do |candidate_identifier, candidate_uri|
          return candidate_identifier.gsub(/^xmlns:/, '') if candidate_uri == uri
        end
        nil
      end

      def used_namespaces
        @used_namespaces ||= {}
      end

      def use_namespace(path, uri)
        @internal_namespace_count ||= 0

        unless identifier = namespace_by_uri(uri)
          identifier = "ins#{@internal_namespace_count}"
          namespaces["xmlns:#{identifier}"] = uri
          @internal_namespace_count += 1
        end

        used_namespaces[path] = identifier
      end

      def types
        @types ||= {}
      end

      # Sets the default namespace identifier.
      attr_writer :namespace_identifier

      # Returns the default namespace identifier.
      def namespace_identifier
        @namespace_identifier ||= :wsdl
      end

      # Accessor for whether all local elements should be namespaced.
      attr_accessor :element_form_default

      # Accessor for the default namespace URI.
      attr_accessor :namespace

      # Accessor for the <tt>Savon::WSSE</tt> object.
      attr_accessor :wsse

      def signature?
        wsse.respond_to?(:signature?) && wsse.signature?
      end

      # Returns the SOAP request encoding. Defaults to "UTF-8".
      def encoding
        @encoding ||= "UTF-8"
      end

      # Sets the SOAP request encoding.
      attr_writer :encoding

      # Accepts a +block+ and yields a <tt>Builder::XmlMarkup</tt> object to let you create
      # custom body XML.
      def body
        @body = yield builder(nil) if block_given?
        @body
      end

      # Sets the SOAP +body+. Expected to be a Hash that can be translated to XML via `Gyoku.xml`
      # or any other Object responding to to_s.
      attr_writer :body

      # Accepts a +block+ and yields a <tt>Builder::XmlMarkup</tt> object to let you create
      # a completely custom XML.
      def xml(directive_tag = :xml, attrs = {})
        @xml = yield builder(directive_tag, attrs) if block_given?
      end

      # Accepts an XML String and lets you specify a completely custom request body.
      attr_writer :xml

      # Returns the XML for a SOAP request.
      def to_xml(clear_cache = false)
        if clear_cache
          @xml = nil
          @header_for_xml = nil
        end

        @xml ||= tag(builder, :Envelope, complete_namespaces) do |xml|
          tag(xml, :Header) { xml << header_for_xml } unless header_for_xml.empty?

          # TODO: Maybe there should be some sort of plugin architecture where
          #       classes like WSSE::Signature can hook into this process.
          body_attributes = (signature? ? wsse.signature.body_attributes : {})

          if input.nil?
            tag(xml, :Body, body_attributes)
          else
            tag(xml, :Body, body_attributes) { xml.tag!(*add_namespace_to_input) { xml << body_to_xml } }
          end
        end
      end

      private

      # Returns a new <tt>Builder::XmlMarkup</tt> object.
      def builder(directive_tag = :xml, attrs = { :encoding => encoding })
        builder = Builder::XmlMarkup.new
        builder.instruct!(directive_tag, attrs) if directive_tag
        builder
      end

      # Expects a builder +xml+ instance, a tag +name+ and accepts optional +namespaces+
      # and a block to create an XML tag.
      def tag(xml, name, namespaces = {}, &block)
        if env_namespace && env_namespace != ""
          xml.tag! env_namespace, name, namespaces, &block
        else
          xml.tag! name, namespaces, &block
        end
      end

      # Returns the complete Hash of namespaces.
      def complete_namespaces
        defaults = SCHEMA_TYPES.dup
        defaults["xmlns:#{namespace_identifier}"] = namespace if namespace
        defaults.merge namespaces
      end

      # Returns the SOAP header as an XML String.
      def header_for_xml
        @header_for_xml ||= (Hash === header ? Gyoku.xml(header) : header) + wsse_header
      end

      # Returns the WSSE header or an empty String in case WSSE was not set.
      def wsse_header
        wsse.respond_to?(:to_xml) ? wsse.to_xml : ""
      end

      # Returns the SOAP body as an XML String.
      def body_to_xml
        return body.to_s unless body.kind_of? Hash
        body_to_xml = element_form_default == :qualified ? add_namespaces_to_body(body) : body
        Gyoku.xml body_to_xml, :element_form_default => element_form_default, :namespace => namespace_identifier
      end

      def add_namespaces_to_body(hash, path = [input[1].to_s])
        return unless hash
        return hash.map { |value| add_namespaces_to_body(value, path) } if hash.kind_of?(Array)
        return hash.to_s unless hash.kind_of? Hash

        hash.inject({}) do |newhash, (key, value)|
          camelcased_key = Gyoku::XMLKey.create(key)
          newpath = path + [camelcased_key]

          if used_namespaces[newpath]
            newhash.merge(
              "#{used_namespaces[newpath]}:#{camelcased_key}" =>
                add_namespaces_to_body(value, types[newpath] ? [types[newpath]] : newpath)
            )
          else
            add_namespaces_to_values(value, path) if key == :order!
            newhash.merge(key => value)
          end
        end
      end

      def add_namespace_to_input
        return input.compact unless used_namespaces[[input[1].to_s]]
        [used_namespaces[[input[1].to_s]], input[1], input[2]]
      end

      def add_namespaces_to_values(values, path)
        values.collect! { |value|
          camelcased_value = Gyoku::XMLKey.create(value)
          namespace_path = path + [camelcased_value.to_s]
          namespace = used_namespaces[namespace_path]
          "#{namespace.blank? ? '' : namespace + ":"}#{camelcased_value}"
        }
      end
    end
  end
end
