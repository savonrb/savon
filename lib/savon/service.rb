require "rubygems"
require "net/http"
require "uri"
require "apricoteatsgorilla"

module Savon

  # Ruby SOAP client library to enjoy.
  #
  # Communicating with a SOAP webservice can be done in two lines of code.
  # Instantiate a new Savon::Service passing in the URI to the WSDL of the
  # service you would like to use. Then call the SOAP service method on your
  # Savon::Service instance (catched via method_missing) and pass in a Hash
  # of options for the service method to receive.
  class Service

    # The logger to use.
    @@logger = nil

    # Initializer expects the WSDL +endpoint+ URI to use and sets up
    # Apricot eats Gorilla.
    #
    # ==== Parameters
    #
    # * +endpoint+ - WSDL endpoint URI to use.
    def initialize(endpoint)
      @uri = URI(endpoint)
      ApricotEatsGorilla.nodes_to_namespace = wsdl.choice_elements
      ApricotEatsGorilla.node_namespace = "wsdl"
    end

    # Returns an instance of the WSDL.
    def wsdl
      @wsdl = Savon::Wsdl.new(@uri, http) if @wsdl.nil?
      @wsdl
    end

    # Sets the Net::HTTP instance to use.
    def http=(http)
      @http = http
    end

    # Sets the logger to use.
    def self.logger=(logger)
      @@logger = logger
    end

  private

    # Sets up and dispatches the SOAP request. Returns a Savon::Response object.
    def call_service
      headers = { "Content-Type" => "text/xml; charset=utf-8", "SOAPAction" => @action }

      body = ApricotEatsGorilla.soap_envelope("wsdl" => wsdl.namespace_uri) do
        ApricotEatsGorilla["wsdl:#{@action}" => @options]
      end

      debug do |logger|
        logger.info "Requesting #{@uri}"
        logger.info headers.map { |key, value| "#{key}: #{value}" }.join("\n")
        logger.info body
      end
      response = @http.request_post(@uri.path, body, headers)
      debug do |logger|
        logger.info "Response (Status #{response.code}):"
        logger.info response.body
      end
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

    # Logs a given +message+ using the @@logger instance or yields the logger
    # to a given +block+ for logging multiple things at once.
    def debug(message = nil)
      if @@logger
        @@logger.info(message) if message
        yield @@logger if block_given?
      end
    end

    # Method missing catches SOAP service methods called on this object. This
    # is the default way of calling a SOAP service. The given +method+ will be
    # validated against the WSDL and dispatched if available. Values supplied
    # through the optional Hash of +options+ will be send to the service method.
    #
    # === Parameters
    #
    # * +method+ - The SOAP service method to call.
    # * +options+ - Hash of options for the service method to receive.
    def method_missing(method, options = {})
      @action, @options = method.to_s, options
      validate_action
      call_service
    end

  end
end