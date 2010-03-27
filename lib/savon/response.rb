module Savon

  # = Savon::Response
  #
  # Savon::Response represents both HTTP and SOAP response.
  #
  # == SOAP fault
  #
  # Assuming the default behavior of raising errors is disabled, you can ask the response object
  # if there was a SOAP fault or an HTTP error and get the SOAP fault or HTTP error message.
  #
  #   response.soap_fault?
  #   # => true
  #
  #   response.soap_fault
  #   # => "(soap:Server) Fault occurred while processing."
  #
  #   response.http_error?
  #   # => true
  #
  #   response.http_error
  #   # => "Not found (404)"
  #
  # == Response as XML
  #
  # To get the raw SOAP response XML, you can call to_xml or to_s on the response object.
  #
  #   response.to_xml
  #   => "<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  #   => "..."
  #   => "</soap:Envelope>"
  #
  # == Response as a Hash
  #
  # You can also let Savon translate the SOAP response body to a Hash.
  #
  #   response.to_hash
  #   => { :findUserByIdResponse => {
  #   =>   :id => "123",
  #   =>   :username => "eve"
  #   =>   :active => true
  #   => }
  #
  # When translating the SOAP response to a Hash, some XML tags and values are converted to more
  # convenient Ruby objects. Translation is done through John Nunemaker's {Crack}[http://github.com/jnunemaker/crack]
  # library along with some custom mapping.
  #
  # * XML tags (Hash keys) are converted to snake_case Symbols and namespaces are stripped off
  # * SOAP xs:nil values are converted to nil objects
  # * XML values specified in xs:DateTime format are converted to DateTime objects
  # * XML values of "true" and "false" are converted to TrueClass and FalseClass
  #
  # == Net::HTTP response
  #
  # If for some reason you need to access the Net::HTTP response object ... you can.
  #
  #   bc. response.http
  #   => #<Net::HTTPOK:0x7f749a1aa4a8>
  class Response

    # The maximum HTTP response code considered to be OK.
    MaxNonErrorResponseCode = 299

    # The global setting of whether to raise errors.
    @@raise_errors = true

    # Sets the global setting of whether to raise errors.
    def self.raise_errors=(raise_errors)
      @@raise_errors = raise_errors
    end

    # Returns the global setting of whether to raise errors.
    def self.raise_errors?
      @@raise_errors
    end

    # Expects a Net::HTTPResponse and handles errors.
    def initialize(http)
      @http = http

      handle_soap_fault
      handle_http_error
    end

    # Returns whether there was a SOAP fault.
    def soap_fault?
      !@soap_fault.blank?
    end

    # Returns the SOAP fault message.
    attr_reader :soap_fault

    # Returns whether there was an HTTP error.
    def http_error?
      !@http_error.blank?
    end

    # Returns the HTTP error message.
    attr_reader :http_error

    # Returns the SOAP response body as a Hash.
    def to_hash
      @hash ||= (Crack::XML.parse(body) rescue {}).find_soap_body
    end

    # Returns the SOAP response XML.
    def to_xml
      body
    end

    # Returns the HTTP response object.
    attr_reader :http

    alias :to_s :to_xml

  private

    # Returns the response body.
    def body
      @body || gzipped_body? ? decoded_body : @http.body
    end

    # Returns whether the body is gzipped.
    def gzipped_body?
      @http["content-encoding"] == "gzip" || @http.body[0..1] == "\x1f\x8b"
    end

    # Returns the gzip decoded body.
    def decoded_body
      gz = Zlib::GzipReader.new StringIO.new(@http.body)
      gz.read
    ensure
      gz.close
    end

    # Handles SOAP faults. Raises a Savon::SOAPFault unless the default behavior of raising errors
    # was turned off.
    def handle_soap_fault
      if soap_fault_message
        @soap_fault = soap_fault_message
        raise Savon::SOAPFault, @soap_fault if self.class.raise_errors?
      end
    end

    # Returns a SOAP fault message in case a SOAP fault was found.
    def soap_fault_message
      @soap_fault_message ||= soap_fault_message_by_version to_hash[:fault]
    end

    # Expects a Hash that might contain information about a SOAP fault. Returns the SOAP fault
    # message in case one was found.
    def soap_fault_message_by_version(soap_fault)
      return unless soap_fault

      if soap_fault.keys.include? :faultcode
        "(#{soap_fault[:faultcode]}) #{soap_fault[:faultstring]}"
      elsif soap_fault.keys.include? :code
        "(#{soap_fault[:code][:value]}) #{soap_fault[:reason][:text]}"
      end
    end

    # Handles HTTP errors. Raises a Savon::HTTPError unless the default behavior of raising errors
    # was turned off.
    def handle_http_error
      if @http.code.to_i > MaxNonErrorResponseCode
        @http_error = "#{@http.message} (#{@http.code})"
        @http_error << ": #{body}" unless body.empty?
        raise Savon::HTTPError, http_error if self.class.raise_errors?
      end
    end

  end
end

