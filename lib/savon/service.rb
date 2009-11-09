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

    attr_reader :response

    def options
      setup_infrastructure unless @options
      @options
    end

    def http
      setup_infrastructure unless @http
      @http
    end

    def wsdl
      setup_infrastructure unless @wsdl
      @wsdl
    end

    # Initializer expects an +endpoint+ URI.
    def initialize(endpoint)
      @endpoint = endpoint
    end

  private

    # Dispatches a SOAP request, handles any HTTP errors and SOAP faults
    # and returns the SOAP response.
    def dispatch(soap_action, soap_body)
      @response = @http.request soap_action, soap_body
      
      
      
      
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

    # Catches calls to SOAP actions, checks if the method called was found in
    # the WSDL and dispatches the SOAP action if it's valid.
    def method_missing(method, *args)
p "method_missing"
      soap_action = camelize method
      soap_body = extract_soap_body args[0]
      setup_infrastructure

      super unless @wsdl.soap_actions.include? soap_action
      dispatch soap_action, soap_body
    end

    def setup_infrastructure
      @options = Options.new
      @options.endpoint = @endpoint
      @http = HTTP.new @options
      @wsdl = WSDL.new @http, @options
      @http.namespace_uri = @wsdl.namespace_uri
    end

    # Returns the SOAP body from given +args+.
    def extract_soap_body(args)
      args = args[:soap_body] if args.kind_of? Hash
      args.kind_of?(String) ? args : ""
    end

    # Converts a given +string+ from snake_case to lowerCamelCase.
    def camelize(string)
      string.to_s.gsub(/_(.)/) { $1.upcase } if string
    end

  end
end
