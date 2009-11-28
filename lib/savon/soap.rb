module Savon
  class SOAP
    include WSSE

    # SOAP namespaces by SOAP version.
    SOAPNamespace = {
      1 => "http://schemas.xmlsoap.org/soap/envelope/",
      2 => "http://www.w3.org/2003/05/soap-envelope"
    }

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml", 2 => "application/soap+xml" }

    def initialize(action, body, options, namespace_uri)
      @action, @body = action, body
      @options, @namespace_uri = options, namespace_uri
    end

    attr_reader :action, :options

    def body
      @xml_body ||= builder.env :Envelope, envelope_namespaces do |xml|
        xml.env(:Header) { envelope_header xml }
        xml.env(:Body) { envelope_body xml }
      end
    end

    def version
      options[:soap_version] || 1 # TODO: default to a class instance variable
    end

  private

    def builder
      @builder ||= Builder::XmlMarkup.new
    end

    def envelope_namespaces
      { "xmlns:env" => SOAPNamespace[version], "xmlns:wsdl" => @namespace_uri }
    end

    def envelope_header(xml)
      wsse_header xml if wsse?
    end

    def envelope_body(xml)
      xml.wsdl(@action.to_sym) { xml << translate_body }
    end

    def translate_body
      @body.to_soap_xml rescue @body.to_s
    end

  end
end