module Savon

  # == Savon::Request
  #
  # Handles both WSDL and SOAP HTTP requests.
  class Request

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml", 2 => "application/soap+xml" }

    # Defines whether to log HTTP requests.
    @log = true

    # The default logger.
    @logger = Logger.new STDOUT

    # The default log level.
    @log_level = :debug

    class << self
      # Sets whether to log HTTP requests.
      attr_writer :log

      # Returns whether to log HTTP requests.
      def log?
        @log
      end

      # Accessor for the default logger.
      attr_accessor :logger

      # Accessor for the default log level.
      attr_accessor :log_level
    end

    # Expects an endpoint String. Raises an exception in case the given
    # +endpoint+ does not seem to be valid.
    def initialize(endpoint)
      raise ArgumentError, "Invalid endpoint: #{endpoint}" unless
        /^(http|https):\/\// === endpoint

      @endpoint = URI endpoint
    end

    # Returns the endpoint URI.
    attr_reader :endpoint

    # Retrieves WSDL document and returns the Net::HTTPResponse.
    def wsdl
      log "Retrieving WSDL from: #{@endpoint}"
      http.get @endpoint.to_s
    end

    # Executes a SOAP request using a given Savon::SOAP instance and
    # returns the Net::HTTPResponse.
    def soap(soap)
      @soap = soap

      log_request
      @response = http.request_post @endpoint.path, @soap.to_xml, http_header
      log_response
      @response
    end

  private

    # Logs the SOAP request.
    def log_request
      log "SOAP request: #{@endpoint}"
      log http_header.map { |key, value| "#{key}: #{value}" }.join( ", " )
      log @soap.to_xml
    end

    # Logs the SOAP response.
    def log_response
      log "SOAP response (status #{@response.code}):"
      log @response.body
    end

    # Returns a Net::HTTP instance.
    def http
      unless @http
        @http ||= Net::HTTP.new @endpoint.host, @endpoint.port
        @http.use_ssl = true if @endpoint.ssl?
      end
      @http
    end

    # Returns a Hash containing the header for an HTTP request.
    def http_header
      { "Content-Type" => ContentType[@soap.version], "SOAPAction" => @soap.action }
    end

    # Logs a given +message+.
    def log(message)
      self.class.logger.send self.class.log_level, message if log?
    end

    # Returns whether logging is possible.
    def log?
      self.class.log? && self.class.logger.respond_to?(self.class.log_level)
    end

  end
end
