module Savon
  class Request

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml", 2 => "application/soap+xml" }

    def initialize(soap_action, soap_body, namespace_uri, options)
      @soap_action = soap_action
      @soap_body = soap_body
      @namespace_uri = namespace_uri
      @options = options
    end

    def headers
      { 'Content-Type' => ContentType[@options.soap_version], 'SOAPAction' => @soap_action }
    end

    def body
      unless @body
        envelope = { 'env:Envelope' => { '$' => '%s' } }
        envelope['env:Envelope'].merge! envelope_namespaces
        envelope = CobraVsMongoose.hash_to_xml envelope
        @body = envelope % (envelope_header << envelope_body)
      end
      @body
    end

  private

    def envelope_namespaces
      namespaces = @options.namespaces.kind_of?(Hash) ? @options.namespaces : {}
      namespaces['@xmlns:env'] = @options.soap_namespace unless namespaces['@xmlns:env']
      namespaces['@xmlns:wsdl'] = @namespace_uri
      namespaces
    end

    def envelope_header
      header = { 'env:Header' => { '$' => '%s' } }
      header = CobraVsMongoose.hash_to_xml header
      header % "" #TODO: add wsse support
    end

    def envelope_body
      body = { 'env:Body' => { "wsdl:#{@soap_action}" => { '$' => '%s' } } }
      body = CobraVsMongoose.hash_to_xml body
      body % @soap_body
    end

  end
end
