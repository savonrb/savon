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

    # Expects a SOAP +endpoint+ String. Also accepts an optional Hash of
    # +options+ for specifying a proxy server and SSL client authentication.
    def initialize(endpoint, options = {})
      @endpoint = URI endpoint
      @proxy = options[:proxy] ? URI(options[:proxy]) : URI("") 
      @ssl = options[:ssl] if options[:ssl]
    end

    # Returns the endpoint URI.
    attr_reader :endpoint

    # Returns the proxy URI.
    attr_reader :proxy

    # Accessor for HTTP open timeout.
    attr_accessor :open_timeout

    # Accessor for HTTP read timeout.
    attr_accessor :read_timeout

    # Sets the +username+ and +password+ for HTTP basic authentication.
    def basic_auth(username, password)
      @http_basic_auth = [username, password]
    end

    # Retrieves WSDL document and returns the Net::HTTPResponse.
    def wsdl
      log "Retrieving WSDL from: #{@endpoint}"
      
      query = @endpoint.path
      query += ('?' + @endpoint.query) if @endpoint.query
      req = Net::HTTP::Get.new query
      req.basic_auth(@endpoint.user, @endpoint.password) if @endpoint.user
      
      http.start {|h| h.request(req) }
    end

    # Executes a SOAP request using a given Savon::SOAP instance and
    # returns the Net::HTTPResponse.
    def soap(soap)
      @soap = soap
      
      log_request

      req = Net::HTTP::Post.new @soap.endpoint.path, http_header
      req.body = @soap.to_xml
      req.basic_auth(@soap.endpoint.user, @soap.endpoint.password) if @soap.endpoint.user
      
      @response = http(@soap.endpoint).start {|h| h.request(req) }
      
      log_response
      @response
    end

  private

    # Logs the SOAP request.
    def log_request
      log "SOAP request: #{@soap.endpoint}"
      log http_header.map { |key, value| "#{key}: #{value}" }.join( ", " )
      log @soap.to_xml
    end

    # Logs the SOAP response.
    def log_response
      log "SOAP response (status #{@response.code}):"
      log @response.body
    end

    # Returns a Net::HTTP instance for a given +endpoint+.
    def http(endpoint = @endpoint)
      @http = Net::HTTP::Proxy(@proxy.host, @proxy.port).new endpoint.host, endpoint.port
      set_http_timeout
      set_ssl_options endpoint.ssl?
      set_ssl_authentication if @ssl
      @http
    end

    # Sets HTTP open and read timeout.
    def set_http_timeout
      @http.open_timeout = @open_timeout if @open_timeout
      @http.read_timeout = @read_timeout if @read_timeout
    end

    # Sets basic SSL options to the +@http+ instance.
    def set_ssl_options(use_ssl)
      @http.use_ssl = use_ssl
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    # Sets SSL client authentication to the +@http+ instance.
    def set_ssl_authentication
      @http.verify_mode = @ssl[:verify] if @ssl[:verify].kind_of? Integer
      @http.cert = @ssl[:client_cert] if @ssl[:client_cert]
      @http.key = @ssl[:client_key] if @ssl[:client_key]
      @http.ca_file = @ssl[:ca_file] if @ssl[:ca_file]
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
