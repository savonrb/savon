module Savon

  # == Savon::Service
  #
  # Savon::Service is a SOAP client library to enjoy. The goal is to minimize
  # the overhead of working with SOAP services and provide a lightweight
  # alternative to other libraries.
  #
  # ==== Example
  #
  #   proxy = Savon::Service.new("http://example.com/ExampleService?wsdl")
  #   response = proxy.find_user_by_id(:id => 123)
  class Service

    # Initializer expects an +endpoint+ URI.
    def initialize(endpoint)
      raise ArgumentError, "Invalid endpoint: #{endpoint}" unless /^http.+/ === endpoint
      @endpoint = URI(endpoint)
    end

    # Returns an instance of Savon::WSDL.
    def wsdl
      @wsdl ||= WSDL.new(@endpoint, http)
    end

  private

    # Dispatches a SOAP request, handles any HTTP errors and SOAP faults
    # and returns the SOAP response.
    def dispatch(soap_action, soap_body, response_xpath)
      ApricotEatsGorilla.nodes_to_namespace = { :wsdl => wsdl.choice_elements }
      headers, body = build_request_parameters(soap_action, soap_body)

      Savon.log("SOAP request: #{@endpoint}")
      Savon.log(headers.map { |k, v| "#{k}: #{v}" }.join(", "))
      Savon.log(body)

      response = http.request_post(@endpoint.path, body, headers)

      Savon.log("SOAP response (status #{response.code})")
      Savon.log(response.body)

      soap_fault = ApricotEatsGorilla[response.body, "//soap:Fault"]
      raise_soap_fault(soap_fault) if soap_fault && !soap_fault.empty?
      raise_http_error(response) if response.code.to_i >= 300

      ApricotEatsGorilla[response.body, response_xpath]
    end

    # Expects the requested +soap_action+ and +soap_body+ and builds and
    # returns the request header and body to dispatch a SOAP request.
    def build_request_parameters(soap_action, soap_body)
      headers = { "Content-Type" => "text/xml; charset=utf-8", "SOAPAction" => soap_action }
      body = ApricotEatsGorilla.soap_envelope(:wsdl => wsdl.namespace_uri) do
        ApricotEatsGorilla["wsdl:#{soap_action}" => soap_body]
      end
      [headers, body]
    end

    # Expects a Hash containing information about a SOAP fault and raises
    # a Savon::SOAPFault.
    def raise_soap_fault(soap_fault)
      raise SOAPFault, "#{soap_fault[:faultcode]}: #{soap_fault[:faultstring]}"
    end

    # Expects a Net::HTTPResponse and raises a Savon::HTTPError.
    def raise_http_error(response)
      raise HTTPError, "#{response.message} (#{response.code}): #{response.body}"
    end

    # Returns a Net::HTTP instance.
    def http
      @http ||= Net::HTTP.new(@endpoint.host, @endpoint.port)
    end

    # Catches calls to SOAP actions, checks if the method called was found in
    # the WSDL and dispatches the SOAP action if it's valid. Takes an optional
    # Hash of options to be passed to the SOAP action and an optional XPath-
    # Expression to define a custom XML root node to start parsing the SOAP
    # response at.
    def method_missing(method, *args)
      soap_action = camelize(method)
      super unless wsdl.soap_actions.include? soap_action
      soap_body = args[0] || {}
      response_xpath = args[1] || "//return"
      dispatch(soap_action, soap_body, response_xpath)
    end

    # Converts a given +string+ from snake_case to lowerCamelCase.
    def camelize(string)
      string.to_s.gsub(/_(.)/) { $1.upcase } if string
    end

  end
end
