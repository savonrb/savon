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

    # The default SOAP version.
    @version = 1

    class << self

      # Accessor for the default SOAP version.
      attr_accessor :version

    end

    # Expects a SOAP +action+, +body+, +options+ and the +namespace_uri+.
    def initialize(action, body, options, namespace_uri)
      @action, @body = action, body
      @options, @namespace_uri = options, namespace_uri
    end

    # Returns the SOAP action.
    attr_reader :action

    # Returns the SOAP options.
    attr_reader :options

    # Returns the XML for a SOAP request.
    def body
      builder = Builder::XmlMarkup.new

      @xml_body ||= builder.env :Envelope, envelope_namespaces do |xml|
        xml.env(:Header) { envelope_header xml }
        xml.env(:Body) { envelope_body xml }
      end
    end

    # Returns the SOAP version to use.
    def version
      @options[:soap_version] || self.class.version
    end

  private

    # Returns a Hash of namespaces for the SOAP envelope.
    def envelope_namespaces
      { "xmlns:env" => SOAPNamespace[version], "xmlns:wsdl" => @namespace_uri }
    end

    # Expects an instance of Builder::XmlMarkup and returns the XML for the
    # SOAP envelope header.
    def envelope_header(xml)
      wsse_header xml if wsse?
    end

    # Expects an instance of Builder::XmlMarkup and returns the XML for the
    # SOAP envelope body.
    def envelope_body(xml)
      xml.wsdl(@action[:input].to_sym) do
        xml << (@body.to_soap_xml rescue @body.to_s)
      end
    end

  end
end
