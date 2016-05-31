require "savon/header"
require "savon/message"
require "nokogiri"
require "builder"
require "gyoku"

module Savon
  class Builder
    attr_reader :multipart

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

      @wsdl      = wsdl
      @globals   = globals
      @locals    = locals
      @signature = @locals[:wsse_signature] || @globals[:wsse_signature]

      @types = convert_type_definitions_to_hash
      @used_namespaces = convert_type_namespaces_to_hash
    end

    def pretty
      Nokogiri.XML(to_s).to_xml(:indent => 2)
    end

    def build_document
      xml_result = tag(builder, :Envelope, namespaces_with_globals) do |xml|
        tag(xml, :Header, header_attributes) { xml << header.to_s } unless header.empty?
        if @globals[:no_message_tag]
          tag(xml, :Body, body_attributes) { xml << message.to_s }
        else
          tag(xml, :Body, body_attributes) { xml.tag!(*namespaced_message_tag) { xml << body_message } }
        end
      end

      # if we have a signature sign the document
      if @signature
        @signature.document = xml_result

        2.times do
          @header = nil
          @signature.document = tag(builder, :Envelope, namespaces_with_globals) do |xml|
            tag(xml, :Header, header_attributes) { xml << header.to_s } unless header.empty?
            if @globals[:no_message_tag]
              tag(xml, :Body, body_attributes) { xml << message.to_s }
            else
              tag(xml, :Body, body_attributes) { xml.tag!(*namespaced_message_tag) { xml << message.to_s } }
            end
          end
        end

        xml_result = @signature.document
      end

      # if there are attachments for the request, we should build a multipart message according to
      # https://www.w3.org/TR/SOAP-attachments
      if @locals[:attachments]
        message = Mail.new
        xml_part = Mail::Part.new do
          content_type 'text/xml'
          body xml_result
          # in Content-Type the start parameter is recommended (RFC 2387)
          content_id '<soap-request-body@soap>'
        end
        message.add_part xml_part

        if @locals[:attachments].is_a? Hash
          @locals[:attachments].each do |content_location, file|
            message.add_file file.clone
            message.parts.last.content_location = content_location.to_s
            message.parts.last.content_id = message.parts.last.content_location
          end
        elsif @locals[:attachments].is_a? Array
          @locals[:attachments].each do |file|
            message.add_file file.clone
            message.parts.last.content_location = file.is_a?(String) ? File.basename(file) : file[:filename]
            message.parts.last.content_id = message.parts.last.content_location
          end
        end
        message.ready_to_send!

        # the mail.body.encoded algorithm reorders the parts, default order is [ "text/plain", "text/enriched", "text/html" ]
        # should redefine the sort order, because the soap request xml should be the first
        message.body.set_sort_order [ "text/xml" ]

        #request.headers["Content-Type"] = "Multipart/Related; boundary=#{message.body.boundary}; type=text/xml; start=\"#{xml_part.content_id}\""
        @multipart = {
          multipart_boundary: message.body.boundary,
          start: xml_part.content_id,
        }
        message.body.encoded(message.content_transfer_encoding)
      else
        xml_result
      end
    end

    def header_attributes
      @globals[:use_wsa_headers] ? { 'xmlns:wsa' => WSA_NAMESPACE } : {}
    end

    def body_attributes
      @body_attributes ||= @signature.nil? ? {} : @signature.body_attributes
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
      return [tag_name] if @wsdl.document? and @wsdl.soap_input(@operation_name.to_sym).is_a?(Hash)
      if namespace_identifier == nil
        [tag_name, message_attributes]
      elsif @used_namespaces[[tag_name.to_s]]
        [@used_namespaces[[tag_name.to_s]], tag_name, message_attributes]
      else
        [namespace_identifier, tag_name, message_attributes]
      end
    end

    def serialized_message_tag
      [:wsdl, @wsdl.soap_input(@operation_name.to_sym).keys.first, {}]
    end

    def serialized_messages
      messages = ""
      message_tag = serialized_message_tag[1]
      @wsdl.soap_input(@operation_name.to_sym)[message_tag].each_pair do |message, type|
        break if @locals[:message].nil?
        message_locals = @locals[:message][message.snakecase.to_sym]
        message_content = Message.new(message_tag, namespace_identifier, @types, @used_namespaces, message_locals, :unqualified, @globals[:convert_request_keys_to], @globals[:unwrap]).to_s
        messages << "<#{message} xsi:type=\"#{type.join(':')}\">#{message_content}</#{message}>"
      end
      messages
    end

    def message_tag
      message_tag = @wsdl.soap_input(@operation_name.to_sym).keys.first if @wsdl.document? and @wsdl.soap_input(@operation_name.to_sym).is_a?(Hash)
      message_tag ||= @locals[:message_tag]
      message_tag ||= @wsdl.soap_input(@operation_name.to_sym) if @wsdl.document?
      message_tag ||= Gyoku.xml_tag(@operation_name, :key_converter => @globals[:convert_request_keys_to])

      @message_tag = message_tag.to_sym
    end

    def message_attributes
      @locals[:attributes] || {}
    end

    def body_message
      if @wsdl.document? and @wsdl.soap_input(@operation_name.to_sym).is_a?(Hash)
        serialized_messages
      else
        message.to_s
      end
    end

    def message
      element_form_default = @globals[:element_form_default] || @wsdl.element_form_default
      # TODO: clean this up! [dh, 2012-12-17]
      Message.new(message_tag, namespace_identifier, @types, @used_namespaces, @locals[:message],
                  element_form_default, @globals[:convert_request_keys_to], @globals[:unwrap])
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
