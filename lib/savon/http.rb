require 'net/http'
require 'rubygems'
require 'cobravsmongoose'

module Savon
  class HTTP

    attr_reader :response

    attr_writer :namespace_uri

    # Initializer expects an instance of Savon::Options.
    def initialize(options)
      @options = options
    end

    # Retrieves and returns the WSDL document from the Web.
    def retrieve_wsdl
      http.get wsdl_endpoint
    end

    def request(soap_action, soap_body)
      request = Request.new soap_action, soap_body, @namespace_uri, @options

p "------------------------------------------------"
p request.body
p "------------------------------------------------"

      @response = http.request_post @options.endpoint.path, request.body, request.headers
      @response.body
      
      
      
      
      
=begin
      ApricotEatsGorilla.nodes_to_namespace = { :wsdl => wsdl.choice_elements }
      headers, body = build_request_parameters(soap_action, soap_body)

      Savon.log("SOAP request: #{@endpoint}")
      Savon.log(headers.map { |k, v| "#{k}: #{v}" }.join(", "))
      Savon.log(body)

      response = http.request_post(@endpoint.path, body, headers)

      Savon.log("SOAP response (status #{response.code}):")
      Savon.log(response.body)

      soap_fault = ApricotEatsGorilla[response.body, "//soap:Fault"]
      raise_soap_fault(soap_fault) if soap_fault && !soap_fault.empty?
      raise_http_error(response) if response.code.to_i >= 300

      if pure_response?
        response.body
      else
        ApricotEatsGorilla[response.body, response_xpath]
      end
=end
    end

    # Returns the WSDL endpoint.
    def wsdl_endpoint
      "#{@options.endpoint.path}?#{@options.endpoint.query}"
    end

  private

    def http
      @http ||= Net::HTTP.new @options.endpoint.host, @options.endpoint.port
    end


      
      
=begin
      namespaces = {} unless namespaces.kind_of? Hash
      if namespaces["xmlns:env"].nil? && SOAPNamespace[version]
        namespaces["xmlns:env"] = SOAPNamespace[version]
      end

      header = xml_node("env:Header") { wsse_soap_header(wsse) }
      body = xml_node("env:Body") { (yield if block_given?) || nil }

      xml_node("env:Envelope", namespaces) { header + body }
      
      
      
      <env:Envelope xmlns:wsdl="http://v1_0.ws.inforeason.marge.blau.de/"
                    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header />
        <env:Body>
          <wsdl:getAllInfoReasons></wsdl:getAllInfoReasons>
        </env:Body>
      </env:Envelope>
=end

=begin
    # Expects the requested +soap_action+ and +soap_body+ and builds and
    # returns the request header and body to dispatch a SOAP request.
    def build_request_parameters(soap_action, soap_body)
      headers = { "Content-Type" => ContentType[@version], "SOAPAction" => soap_action }
      namespaces = { "xmlns:wsdl" => wsdl.namespace_uri }

      body = ApricotEatsGorilla.soap_envelope(namespaces, wsse, @version) do
        ApricotEatsGorilla["wsdl:#{soap_action}" => soap_body]
      end
      [headers, body]
    end

    # Returns the WSSE arguments if :wsse_username and :wsse_password are set.
    def wsse
      if @wsse_username && @wsse_password
        { :username => @wsse_username, :password => @wsse_password, :digest => wsse_digest? }
      else
        nil
      end
    end

    # Expects a Hash containing information about a SOAP fault and raises
    # a Savon::SOAPFault.
    def raise_soap_fault(soap_fault)
      message = case @version
        when 1
          "#{soap_fault[:faultcode]}: #{soap_fault[:faultstring]}"
        else
          "#{soap_fault[:code][:value]}: #{soap_fault[:reason][:text]}"
      end
      raise SOAPFault, message
    end

    # Expects a Net::HTTPResponse and raises a Savon::HTTPError.
    def raise_http_error(response)
      raise HTTPError, "#{response.message} (#{response.code}): #{response.body}"
    end
=end

  end
end
