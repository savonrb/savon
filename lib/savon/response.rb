module Savon

  # == Savon::Response
  #
  # Represents the HTTP and SOAP response.
  class Response

    # The default of whether to raise errors.
    @raise_errors = true

    class << self

      # Sets the default of whether to raise errors.
      attr_writer :raise_errors

      # Returns the default of whether to raise errors.
      def raise_errors?
        @raise_errors
      end

    end

    # Expects a Net::HTTPResponse and handles errors.
    def initialize(response)
      @response = response

      handle_soap_fault
      handle_http_error
    end

    # Returns whether there was a SOAP fault.
    def soap_fault?
      @soap_fault
    end

    # Returns the SOAP fault message.
    attr_reader :soap_fault

    # Returns whether there was an HTTP error.
    def http_error?
      @http_error
    end

    # Returns the HTTP error message.
    attr_reader :http_error

    # Returns the SOAP response as a Hash.
    def to_hash
      @body.find_regexp(/.+/).map_soap_response
    end

    # Returns the SOAP response XML.
    def to_xml
      @response.body
    end

    alias :to_s  :to_xml

  private

    # Returns the SOAP response body as a Hash.
    def body
      unless @body
        body = Crack::XML.parse @response.body
        @body = body.find_regexp [/.+:Envelope/, /.+:Body/]
      end
      @body
    end

    # Handles SOAP faults. Raises a Savon::SOAPFault unless the default
    # behavior of raising errors was turned off.
    def handle_soap_fault
      if soap_fault_message
        @soap_fault = soap_fault_message
        raise Savon::SOAPFault, soap_fault_message if self.class.raise_errors?
      end
    end

    # Returns a SOAP fault message in case a SOAP fault was found.
    def soap_fault_message
      unless @soap_fault_message
        soap_fault = body.find_regexp [/.+:Fault/]
        @soap_fault_message = soap_fault_message_by_version(soap_fault)
      end
      @soap_fault_message
    end

    # Expects a Hash that might contain information about a SOAP fault.
    # Returns the SOAP fault message in case one was found.
    def soap_fault_message_by_version(soap_fault)
      if soap_fault.keys.include? "faultcode"
        "(#{soap_fault['faultcode']}) #{soap_fault['faultstring']}"
      elsif soap_fault.keys.include? "Code"
        # SOAP 1.2 error code element is capitalized, see: http://www.w3.org/TR/soap12-part1/#faultcodeelement
        "(#{soap_fault['Code']['Value']}) #{soap_fault['Reason']['Text']}"
      end
    end

    # Handles HTTP errors. Raises a Savon::HTTPError unless the default
    # behavior of raising errors was turned off.
    def handle_http_error
      if @response.code.to_i >= 300
        @http_error = "#{@response.message} (#{@response.code})"
        @http_error << ": #{@response.body}" unless @response.body.empty?
        raise Savon::HTTPError, http_error if self.class.raise_errors?
      end
    end

  end
end
