require 'net/http'

module Savon
  class HTTP

    # Initializer expects an instance of Savon::Options.
    def initialize(options)
      @options = options
    end

    # Retrieves and returns the WSDL document from the Web.
    def retrieve_wsdl
      http.get wsdl_endpoint
    end

    def perform_soap_request
      
    end

    # Returns the WSDL endpoint.
    def wsdl_endpoint
      "#{@options.endpoint.path}?#{@options.endpoint.query}"
    end

  private

    def http
      @http ||= Net::HTTP.new(@options.endpoint.host, @options.endpoint.port)
    end

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
