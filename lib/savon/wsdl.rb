module Savon

  # Savon::WSDL
  #
  # Represents the WSDL document.
  class WSDL

    # Initializer, expects a Savon::Request.
    def initialize(request)
      @request = request
    end

    # Sets whether to use the WSDL.
    attr_writer :enabled

    # Returns whether to use the WSDL. Defaults to +true+.
    def enabled?
      @enabled.nil? ? true : @enabled
    end

    # Returns the namespace URI of the WSDL.
    def namespace_uri
      @namespace_uri ||= stream.namespace_uri
    end

    # Returns an Array of available SOAP actions.
    def soap_actions
      @soap_actions ||= stream.operations.keys
    end

    # Returns a Hash of SOAP operations including their corresponding
    # SOAP actions and inputs.
    def operations
      @operations ||= stream.operations
    end

    # Returns the SOAP endpoint.
    def soap_endpoint
      @soap_endpoint ||= stream.soap_endpoint
    end

    # Returns +true+ for available methods and SOAP actions.
    def respond_to?(method)
      return true if soap_actions.include? method
      super
    end

    # Returns the raw WSDL document.
    def to_s
      @document ||= @request.wsdl.body
    end

  private

    # Returns the Savon::WSDLStream.
    def stream
      unless @stream
        @stream = WSDLStream.new
        REXML::Document.parse_stream to_s, @stream
      end
      @stream
    end

  end
end
