require "rubygems"
require "net/http"
require "uri"
require "apricoteatsgorilla"

module Savon

  # Savon is a lightweight SOAP client.
  #
  # Instantiate Savon::Service and pass in the WSDL of the service you would
  # like to use. Then just call the SOAP service method on your Savon::Service
  # instance (catched via method_missing) and pass in a Hash of options for the
  # service method to receive.
  #
  # === Usage example
  #
  #   proxy = Savon::Service.new "http://example.com/ExampleService?wsdl"
  #   response = proxy.findExampleById(:id => 123)
  #
  # === Check for available SOAP service methods
  #
  #   proxy.wsdl.service_methods
  #   # => [ "findExampleById", "findExampleByName" ]
  #
  # === Response formats
  #
  #   # raw XML response:
  #   response.to_s
  #
  #   # response as a Hash
  #   response.to_hash
  #
  #   # response as a Hash starting at a custom root node (via XPath)
  #   response.to_hash("//item")
  #
  #   # response as a Mash
  #   response.to_mash
  #
  #   # response as a Mash starting at a custom root node (via XPath)
  #   response.to_mash("//user/email")
  class Service

    # Sets the Net::HTTP connection instance to use.
    attr_writer :http

    # Initializer sets the WSDL +endpoint+ URI.
    #
    # ==== Parameters
    #
    # * +endpoint+ - The WSDL endpoint URI.
    def initialize(endpoint)
      @uri = URI(endpoint)
    end

    # Returns an instance of the WSDL.
    def wsdl
      @wsdl = Savon::Wsdl.new(@uri, http) if @wsdl.nil?
      @wsdl
    end

  private

    # Prepares and processes the SOAP request. Returns a Savon::Response object.
    def call_service
      headers = { "Content-Type" => "text/xml; charset=utf-8", "SOAPAction" => @action }
      body = ApricotEatsGorilla.soap_envelope("wsdl" => wsdl.namespace_uri) do
        ApricotEatsGorilla["wsdl:#{@action}" => namespaced_options]
      end
      response = @http.request_post(@uri.path, body, headers)
      Savon::Response.new(response)
    end

    # Returns the Net::HTTP instance to use.
    def http
      if @http.nil?
        raise ArgumentError, "Invalid endpoint URI" unless @uri.scheme
        @http = Net::HTTP.new(@uri.host, @uri.port)
      end
      @http
    end

    # Checks if the requested SOAP service method is available.
    # Raises an ArgumentError in case it is not.
    def validate_action
      unless wsdl.service_methods.include? @action
        raise ArgumentError, "Invalid service method '#{@action}'"
      end
    end

    # Checks if there were any choice elements found in the WSDL and namespaces
    # the corresponding keys from the passed in Hash of options.
    def namespaced_options
      return @options if wsdl.choice_elements.empty?

      options = {}
      @options.each do |key, value|
        key = "wsdl:#{key}" if wsdl.choice_elements.include? key.to_s

        current = options[key]
        case current
        when Array
          options[key] << value
        when nil
          options[key] = value
        else
          options[key] = [current.dup, value]
        end
      end
      options
    end

    # Intercepts calls to SOAP service methods.
    #
    # === Parameters
    #
    # * +method+ - The SOAP service method to call.
    # * +options+ - Hash of options for the service method to receive.
    def method_missing(method, options = {})
      @action = method.to_s
      @options = options
      validate_action
      call_service
    end

  end
end