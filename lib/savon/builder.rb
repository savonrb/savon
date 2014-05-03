require "savon/header"
require "savon/message"
require "nokogiri"
require "builder"
require "gyoku"

module Savon
  class Builder

    SCHEMA_TYPES = {
      "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
    }

    SOAP_NAMESPACE = {
      1 => "http://schemas.xmlsoap.org/soap/envelope/",
      2 => "http://www.w3.org/2003/05/soap-envelope"
    }

    WSA_NAMESPACE = "http://www.w3.org/2005/08/addressing"

    def initialize(operation_name, wsdl, globals, locals)
      @operation_name = operation_name

      @wsdl    = wsdl
      @globals = globals
      @locals  = locals

      @types = convert_type_definitions_to_hash
      @used_namespaces = convert_type_namespaces_to_hash
    end

    def pretty
      Nokogiri.XML(to_s).to_xml(:indent => 2)
    end

    def build_document
      tag(builder, :Envelope, namespaces_with_globals) do |xml|
        tag(xml, :Header, header_attributes) { xml << header.to_s } unless header.empty?
        tag(xml, :Body, body_attributes) { xml.tag!(*namespaced_message_tag) { xml << message.to_s } }
      end
    end

    def header_attributes
       { 'xmlns:wsa' => WSA_NAMESPACE } if @globals[:use_wsa_headers]
    end

    def body_attributes
    end

    def to_s
      return @locals[:xml] if @locals.include? :xml
      build_document
    end

    private

    def convert_type_definitions_to_hash
      @wsdl.type_definitions.inject({}) do |memo, (path, type)|
        memo[path] = type
        memo
      end
    end

    def convert_type_namespaces_to_hash
      @wsdl.type_namespaces.inject({}) do |memo, (path, uri)|
        key, value = use_namespace(path, uri)
        memo[key] = value
        memo
      end
    end

    def use_namespace(path, uri)
      @internal_namespace_count ||= 0

      unless identifier = namespace_by_uri(uri)
        identifier = "ins#{@internal_namespace_count}"
        namespaces["xmlns:#{identifier}"] = uri
        @internal_namespace_count += 1
      end

      [path, identifier]
    end

    def namespaces_with_globals
      namespaces.merge @globals[:namespaces]
    end

    def namespaces
      @namespaces ||= begin
        namespaces = SCHEMA_TYPES.dup

        if namespace_identifier == nil
          namespaces["xmlns"] = @globals[:namespace] || @wsdl.namespace
        else
          namespaces["xmlns:#{namespace_identifier}"] = @globals[:namespace] || @wsdl.namespace
        end

        key = ["xmlns"]
        key << env_namespace if env_namespace && env_namespace != ""
        namespaces[key.join(":")] = SOAP_NAMESPACE[@globals[:soap_version]]

        namespaces
      end
    end

    def env_namespace
      @env_namespace ||= @globals[:env_namespace] || :env
    end

    def header
      @header ||= Header.new(@globals, @locals)
    end

    def namespaced_message_tag
      tag_name = message_tag
      if namespace_identifier == nil
        [tag_name, message_attributes]
      elsif @used_namespaces[[tag_name.to_s]]
        [@used_namespaces[[tag_name.to_s]], tag_name, message_attributes]
      else
        [namespace_identifier, tag_name, message_attributes]
      end
    end

    def message_tag
      message_tag = @locals[:message_tag]
      message_tag ||= @wsdl.soap_input(@operation_name.to_sym) if @wsdl.document?
      message_tag ||= Gyoku.xml_tag(@operation_name, :key_converter => @globals[:convert_request_keys_to])

      @message_tag = message_tag.to_sym
    end

    def message_attributes
      @locals[:attributes] || {}
    end

    def message
      element_form_default = @globals[:element_form_default] || @wsdl.element_form_default
      # TODO: clean this up! [dh, 2012-12-17]
      Message.new(message_tag, namespace_identifier, @types, @used_namespaces, @locals[:message],
                  element_form_default, @globals[:convert_request_keys_to])
    end

    def namespace_identifier
      return @globals[:namespace_identifier] if @globals.include? :namespace_identifier
      return @namespace_identifier if @namespace_identifier

      operation = @wsdl.operations[@operation_name] if @wsdl.document?
      namespace_identifier = operation[:namespace_identifier] if operation
      namespace_identifier ||= "wsdl"

      @namespace_identifier = namespace_identifier.to_sym
    end

    def namespace_by_uri(uri)
      namespaces.each do |candidate_identifier, candidate_uri|
        return candidate_identifier.gsub(/^xmlns:/, '') if candidate_uri == uri
      end
      nil
    end

    def builder
      builder = ::Builder::XmlMarkup.new
      builder.instruct!(:xml, :encoding => @globals[:encoding])
      builder
    end

    def tag(xml, name, namespaces = {}, &block)
      if env_namespace && env_namespace != ""
        xml.tag! env_namespace, name, namespaces, &block
      else
        xml.tag! name, namespaces, &block
      end
    end

  end
end
