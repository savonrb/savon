module Savon
  class Request
    include Validation

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml", 2 => "application/soap+xml" }

    @logger = Logger.new STDOUT

    @log_level = :debug

    class << self
      attr_accessor :logger, :log_level
    end

    def initialize(endpoint)
      validate! :endpoint, endpoint
      @endpoint = URI endpoint
    end

    attr_reader :endpoint

    def wsdl
      log "Retrieving WSDL from: #{@endpoint}"
      http.get @endpoint.to_s
    end

    def soap(soap)
      @soap = soap

      log_request
      @response = http.request_post @endpoint.path, @soap.body, http_header
      log_response
      @response
    end

  private

    def http
      unless @http
        @http ||= Net::HTTP.new @endpoint.host, @endpoint.port
        @http.use_ssl = true if @endpoint.ssl?
      end
      @http
    end

    def http_header
      { "Content-Type" => ContentType[@soap.version], "SOAPAction" => @soap.action }
    end

    def log_request
      log "SOAP request: #{@endpoint}"
      log http_header.map { |key, value| "#{key}: #{value}" }.join ", "
      log @soap.body
    end

    def log_response
      log "SOAP response (status #{@response.code}):"
      log @response.body
    end

    def log(message)
      self.class.logger.send self.class.log_level, message if log?
    end

    def log?
      self.class.logger && self.class.logger.respond_to?(self.class.log_level)
    end

  end
end