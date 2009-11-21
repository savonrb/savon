module Savon
  class Request

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
        envelope = { "env:Envelope" => { "$" => "%s" } }
        envelope["env:Envelope"].merge! envelope_namespaces
        envelope = CobraVsMongoose.hash_to_xml envelope
        @body = envelope % (envelope_header << envelope_body)
      end
      @body
    end

  private

    def envelope_namespaces
      { "@xmlns:env" => SOAPNamespace[savon_config.soap_version],
        "@xmlns:wsdl" => @namespace_uri }
    end

    def envelope_header
      header = { "env:Header" => {} }
      header["env:Header"] = envelope_wsse_header if savon_config.wsse?
      CobraVsMongoose.hash_to_xml header
    end

    def envelope_wsse_header
      created_at = Time.now.strftime Savon::SOAPDateTimeFormat

      xml_node("wsse:Security", "xmlns:wsse" => WSENamespace) do
        xml_node("wsse:UsernameToken", "xmlns:wsu" => WSUNamespace) do
          xml_node("wsse:Username") { username } <<
          password_node(password, created_at, digest) <<
          xml_node("wsse:Nonce") { nonce(created_at) } <<
          xml_node("wsu:Created") { created_at }
        end
      end
    end

    def envelope_body
      body = { "env:Body" => { "wsdl:#{@soap_action}" => { "$" => "%s" } } }
      body = CobraVsMongoose.hash_to_xml body
      body % translate_soap_body
    end

    def translate_soap_body
      return @soap_body.to_s unless @soap_body.kind_of? Hash
      CobraVsMongoose.hash_to_xml @soap_body.soap_compatible
    end

  end
end
