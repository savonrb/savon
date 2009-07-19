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

    # The logger instance to use.
    @@logger = nil

    # The log level to use.
    @@log_level = :debug

    # Initializer expects the WSDL +endpoint+ URI and defines nodes to
    # namespace for Apricot eats Gorilla.
    def initialize(endpoint)
      @uri = URI(endpoint)
      ApricotEatsGorilla.nodes_to_namespace = wsdl.choice_elements
      ApricotEatsGorilla.node_namespace = "wsdl"
    end

    # Returns an instance of the Savon::Wsdl.
    def wsdl
      @wsdl = Savon::Wsdl.new(@uri, http) unless @wsdl
      @wsdl
    end

    # Sets the Net::HTTP instance to use.
    def http=(http)
      @http = http
    end

    # Sets the logger instance to use.
    def self.logger=(logger)
      @@logger = logger
    end

    # Sets the log level to use.
    def self.log_level=(log_level)
      @@log_level = log_level
    end

  private

    # Constructs and dispatches the SOAP request. Returns a Savon::Response.
    def dispatch(root_node = nil)
      headers = { "Content-Type" => "text/xml; charset=utf-8", "SOAPAction" => @soap_action }

      body = ApricotEatsGorilla.soap_envelope("wsdl" => wsdl.namespace_uri) do
        ApricotEatsGorilla["wsdl:#{@soap_action}" => @options]
      end

      debug do |logger|
        logger.send @@log_level, "Requesting #{@uri}"
        logger.send @@log_level, headers.map { |key, value| "#{key}: #{value}" }.join("\n")
        logger.send @@log_level, body
      end
      response = http.request_post(@uri.path, body, headers)
      debug do |logger|
        logger.send @@log_level, "Response (Status #{response.code}):"
        logger.send @@log_level, response.body
      end
      Savon::Response.new response, root_node
    end

    # Returns the Net::HTTP instance to use.
    def http
      if @http.nil?
        raise ArgumentError, "Invalid endpoint URI: #{@uri}" unless @uri.scheme
        @http = Net::HTTP.new(@uri.host, @uri.port)
      end
      @http
    end

    # Checks if the requested SOAP action was found on the WSDL.
    # Raises an ArgumentError in case it was not found.
    def validate_soap_action
      unless wsdl.service_methods.include? @soap_action
        raise ArgumentError, "Invalid service method: #{@soap_action}"
      end
    end

    # Logs a given +message+ using the +@@logger+ instance or yields the logger
    # to a given +block+ for logging multiple messages at once.
    def debug(message = nil)
      if @@logger
        @@logger.send(@@log_level, message) if message
        yield @@logger if block_given?
      end
    end

    # Catches SOAP actions called on the Savon::Service instance.
    # This is the default way of calling a SOAP action.
    # 
    # The given +method+ will be validated against available SOAP actions found
    # on the WSDL and dispatched if available. Options for the SOAP action to
    # receive can be given through the optional Hash of +options+. A custom
    # +root_node+ to start parsing the SOAP response at might be supplied as well.
    def method_missing(method, options = {}, root_node = nil)
      @soap_action = ApricotEatsGorilla.to_lower_camel_case(method)
      @options = options
      validate_soap_action
      dispatch(root_node)
    end

  end
end