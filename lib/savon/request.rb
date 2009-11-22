require "base64"
require "digest/sha1"
require "rubygems"
require "builder"

module Savon
  class Request
    include WSSE

    # SOAP namespaces by SOAP version.
    SOAPNamespace = {
      1 => "http://schemas.xmlsoap.org/soap/envelope/",
      2 => "http://www.w3.org/2003/05/soap-envelope"
    }

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml", 2 => "application/soap+xml" }

    attr_accessor :soap_action, :soap_body, :namespace_uri

    def headers
      @headers ||= {
        "Content-Type" => ContentType[savon_config.soap_version],
        "SOAPAction" => @soap_action
      }
    end

    def body
      unless @body
        builder = Builder::XmlMarkup.new

        @body = builder.env(:Envelope, envelope_namespaces) do |xml|
          xml.env(:Header) { envelope_header xml }
          xml.env(:Body) { envelope_body xml }
        end
      end
      @body
    end

  private

    def envelope_header(header)
      return nil unless savon_config.wsse?
      wsse_header header
    end

    def envelope_namespaces
      { "xmlns:env" => SOAPNamespace[savon_config.soap_version],
        "xmlns:wsdl" => @namespace_uri }
    end

    def envelope_body(xml)
      xml.wsdl(:"#{@soap_action}") { xml << translate_soap_body }
    end

    def translate_soap_body
      return @soap_body.to_s unless @soap_body.kind_of? Hash
      translate_soap_body_hash
    end

    def translate_soap_body_hash
      return translate_multiple_root_nodes if @soap_body.keys.length > 1
      CobraVsMongoose.hash_to_xml @soap_body.soap_request_mapping
    end

    def translate_multiple_root_nodes
      @soap_body.inject("") do |xml, (key, value)|
        xml << CobraVsMongoose.hash_to_xml(
          { key => value }.soap_request_mapping
        )
      end
    end

  end
end