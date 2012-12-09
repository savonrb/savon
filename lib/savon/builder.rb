require "savon/header"
require "savon/message"
require "builder"
require "gyoku"

module Savon
  class Builder

    SCHEMA_TYPES = {
      "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
    }

    def initialize(operation_name, wsdl, globals, locals)
      @operation_name = operation_name

      @wsdl    = wsdl
      @globals = globals
      @locals  = locals
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

    def to_s
      return @locals[:xml] if @locals.include? :xml

      tag(builder, :Envelope, namespaces) do |xml|
        tag(xml, :Header) { xml << header.to_s } unless header.empty?
        tag(xml, :Body)   { xml.tag!(*message_tag) { xml << message.to_s } }
      end
    end

    private

    def namespaces
      @namespaces ||= begin
        env_namespace = @globals[:env_namespace]

        namespaces = SCHEMA_TYPES.dup
        namespaces["xmlns:#{@globals[:namespace_identifier]}"] = @globals[:namespace]

        key = ["xmlns"]
        key << env_namespace if env_namespace && env_namespace != ""
        namespaces[key.join(":")] = SOAP::NAMESPACE[@globals[:soap_version]]

        namespaces
      end
    end

    def header
      @header ||= Header.new(@globals, @locals)
    end

    def message_tag
      return [@globals[:namespace_identifier], @locals[:message_tag].to_sym] unless used_namespaces[[@operation_name.to_s]]
      [used_namespaces[[@operation_name.to_s]], @locals[:message_tag].to_sym]
    end

    def message
      @message ||= Message.new(@operation_name, @globals[:namespace_identifier], @used_namespaces, @globals, @locals)
    end

    def used_namespaces
      @used_namespaces ||= {}
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
      env_namespace = @globals[:env_namespace]

      if env_namespace && env_namespace != ""
        xml.tag! env_namespace, name, namespaces, &block
      else
        xml.tag! name, namespaces, &block
      end
    end

  end
end
