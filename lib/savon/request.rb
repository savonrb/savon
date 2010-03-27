module Savon

  # = Savon::Request
  #
  # Savon::Request handles both WSDL and SOAP requests.
  #
  # == The Net::HTTP object
  #
  # You can access the Net::HTTP object used for both WSDL and SOAP requests via:
  #
  #   client.request.http
  #
  # Here's an example of how to set open and read timeouts on the Net::HTTP object.
  #
  #   client.request.http.open_timeout = 30
  #   client.request.http.read_timeout = 30
  #
  # Please refer to the {Net::HTTP documentation}[http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/]
  # for more information.
  #
  # == HTTP basic authentication
  #
  # Setting credentials for HTTP basic authentication:
  #
  #   client.request.basic_auth "username", "password"
  #
  # == SSL client authentication
  #
  # You can use the methods provided by Net::HTTP to set SSL client authentication or use a shortcut:
  #
  #   client.request.http.ssl_client_auth(
  #     :cert => OpenSSL::X509::Certificate.new(File.read("client_cert.pem")),
  #     :key => OpenSSL::PKey::RSA.new(File.read("client_key.pem"), "password if one exists"),
  #     :ca_file => "cacert.pem",
  #     :verify_mode => OpenSSL::SSL::VERIFY_PEER
  #   )
  #
  # == HTTP headers
  #
  # There's an accessor for the Hash of HTTP headers sent with any SOAP call:
  #
  #   client.request.headers["custom"] = "header"
  class Request
    include Logger

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml;charset=UTF-8", 2 => "application/soap+xml;charset=UTF-8" }

    # Expects a WSDL or SOAP +endpoint+ and accepts a custom +proxy+ address.
    def initialize(endpoint, options = {})
      @endpoint = URI endpoint
      @proxy = URI options[:proxy] || ""
      headers["Accept-encoding"] = "gzip,deflate" if options[:gzip]
    end

    # Returns the endpoint URI.
    attr_reader :endpoint

    # Returns the proxy URI.
    attr_reader :proxy

    # Returns the HTTP headers for a SOAP request.
    def headers
      @headers ||= {}
    end

    # Sets the HTTP headers for a SOAP request.
    def headers=(headers)
      @headers = headers if headers.kind_of? Hash
    end

    # Sets the +username+ and +password+ for HTTP basic authentication.
    def basic_auth(username, password)
      @basic_auth = [username, password]
    end

    # Retrieves WSDL document and returns the Net::HTTP response.
    def wsdl
      log "Retrieving WSDL from: #{@endpoint}"
      http.endpoint @endpoint.host, @endpoint.port
      http.use_ssl = @endpoint.ssl?
      http.start { |h| h.request request(:wsdl) }
    end

    # Executes a SOAP request using a given Savon::SOAP instance and returns the Net::HTTP response.
    def soap(soap)
      @soap = soap
      http.endpoint @soap.endpoint.host, @soap.endpoint.port
      http.use_ssl = @soap.endpoint.ssl?

      log_request
      @response = http.start do |h|
        h.request request(:soap) { |request| request.body = @soap.to_xml }
      end
      log_response
      @response
    end

    # Returns the Net::HTTP object.
    def http
      @http ||= Net::HTTP::Proxy(@proxy.host, @proxy.port).new @endpoint.host, @endpoint.port
    end

  private

    # Logs the SOAP request.
    def log_request
      log "SOAP request: #{@soap.endpoint}"
      log soap_headers.merge(headers).map { |key, value| "#{key}: #{value}" }.join(", ")
      log @soap.to_xml
    end

    # Logs the SOAP response.
    def log_response
      log "SOAP response (status #{@response.code}):"
      log @response.body
    end

    # Returns a Net::HTTP request for a given +type+. Yields the request to an optional block.
    def request(type)
      request = case type
        when :wsdl then Net::HTTP::Get.new @endpoint.request_uri
        when :soap then Net::HTTP::Post.new @soap.endpoint.request_uri, soap_headers.merge(headers)
      end

      request.basic_auth(*@basic_auth) if @basic_auth
      yield request if block_given?
      request
    end

    # Returns a Hash containing the SOAP headers for an HTTP request.
    def soap_headers
      { "Content-Type" => ContentType[@soap.version], "SOAPAction" => @soap.action }
    end

  end
end

