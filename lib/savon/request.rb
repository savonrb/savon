module Savon

  # == Savon::Request
  #
  # Handles both WSDL and SOAP HTTP requests.
  class Request

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml", 2 => "application/soap+xml" }

    # Whether to log HTTP requests.
    @@log = true

    # The default logger.
    @@logger = Logger.new STDOUT

    # The default log level.
    @@log_level = :debug

    # Sets whether to log HTTP requests.
    def self.log=(log)
      @@log = log
    end

    # Returns whether to log HTTP requests.
    def self.log?
      @@log
    end

    # Sets the logger.
    def self.logger=(logger)
      @@logger = logger
    end

    # Returns the logger.
    def self.logger
      @@logger
    end

    # Sets the log level.
    def self.log_level=(log_level)
      @@log_level = log_level
    end

    # Returns the log level.
    def self.log_level
      @@log_level
    end

    # Expects an +endpoint+ String. Also accepts an optional +proxy+ String.
    # Raises an exception in case the given +endpoint+ or +proxy+ does not
    # seem to be valid.
    def initialize(endpoint, proxy = "")
      raise ArgumentError, "Invalid endpoint: #{endpoint}" unless valid_uri?(endpoint)
      raise ArgumentError, "Invalid proxy: #{proxy}" unless proxy.empty? || valid_uri?(proxy)

      @endpoint = URI endpoint
      @proxy = URI proxy
    end

    # Returns the endpoint URI.
    attr_reader :endpoint

    # Returns the proxy URI
    attr_reader :proxy

    # Sets the open timeout for HTTP requests.
    def open_timeout=(sec)
      http.open_timeout = sec
    end

    # Sets the read timeout for HTTP requests.
    def read_timeout=(sec)
      http.read_timeout = sec
    end

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
        @http ||= Net::HTTP::Proxy(@proxy.host, @proxy.port).new @endpoint.host, @endpoint.port
        @http.use_ssl = true if @endpoint.ssl?
      end
      @http
    end

    # Returns a Hash containing the header for an HTTP request.
    def http_header
      { "Content-Type" => ContentType[@soap.version], "SOAPAction" => @soap.action }
    end

    # Returns whether a given URI seems to be valid.
    def valid_uri?(uri)
      /^(http|https):\/\// === uri
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
