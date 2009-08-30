%w(rubygems net/http uri apricoteatsgorilla).each do |gem|
  require gem
end

module Savon
  module Service

    HTTPError = Class.new(RuntimeError)
    SOAPFault = Class.new(RuntimeError)

    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods

      # Dual-purpose accessor. Sets the WSDL endpoint to the given +endpoint+
      # if it is a String, returns the existing endpoint otherwise.
      def endpoint(endpoint = nil)
        @endpoint = URI(endpoint) if endpoint.kind_of?(String)
        @endpoint
      end

      # Dual-purpose accessor. Adds SOAP accessors to the existing accessors
      # if +soap_attr+ is a Hash, returns the existing accessors otherwise.
      def soap_attr(soap_attr = {})
        return @soap_attr unless soap_attr.kind_of?(Hash)
        @soap_attr ||= {}
        @soap_attr.update(soap_attr)
      end
    end

    def wsdl
      @wsdl = Savon::Wsdl.new(@endpoint, http) unless @wsdl
      @wsdl
    end

  private

    def dispatch(soap_action, soap_body)
      ApricotEatsGorilla.nodes_to_namespace = { :wsdl => wsdl.choice_elements }

      headers = { "Content-Type" => "text/xml; charset=utf-8", "SOAPAction" => soap_action }
      body = ApricotEatsGorilla.soap_envelope(:wsdl => wsdl.namespace_uri) do
        ApricotEatsGorilla["wsdl:#{soap_action}" => soap_body]
      end
      @soap_response = http.request_post(@endpoint.path, body, headers)

      soap_fault = ApricotEatsGorilla[@soap_response.body, "//soap:Fault"]
      handle_soap_fault(soap_fault) unless soap_fault.nil? || soap_fault.empty?
      handle_http_error if @soap_response.code.to_i >= 300 && !@soap_fault

      @soap_attr.each { |attr, xpath| create_soap_attr(attr, xpath) }
    end

    def create_soap_attr(attr, xpath)
      instance_variable_set("@#{attr}", ApricotEatsGorilla[@soap_response.body, xpath])
      self.class.send(:define_method, attr.to_sym, proc { instance_variable_get("@#{attr}") })
      self.class.send(:define_method, "#{attr}=", proc { |value| instance_variable_set("@#{attr}", value) })
    end

    def handle_http_error
      @http_error = true
      on_http_error(@soap_response.code, @soap_response.message, @soap_response.body)
    end

    def on_http_error(code, message, body)
      raise HTTPError, "HTTPError #{message} (#{code}) #{body}"
    end

    def handle_soap_fault(soap_fault)
      @soap_fault = true
      on_soap_fault(soap_fault[:faultcode], soap_fault[:faultstring])
    end

    # Raises an error
    def on_soap_fault(code, message)
      raise SOAPFault, "SOAPFault (#{code}) #{message}"
    end

    def http
      return @http unless @http.nil?
      raise ArgumentError, "Invalid endpoint URI" if @endpoint.nil? || !@endpoint.scheme
      @http = Net::HTTP.new(@endpoint.host, @endpoint.port)
    end

    def method_missing(method, *args)
      soap_action = to_lower_camel_case(method)
      soap_body = args.first
      inherit_attributes
      super unless wsdl.service_methods.include?(soap_action)
      dispatch(soap_action, soap_body)
    end

    # Inherits attributes defined at class instance level.
    def inherit_attributes
      @endpoint = self.class.endpoint
      @soap_attr = self.class.soap_attr
    end

    # Converts a given given +string+ from snake_case to lowerCamelCase.
    def to_lower_camel_case(string)
      string.to_s.gsub(/_(.)/) { $1.upcase }
    end
  end
end