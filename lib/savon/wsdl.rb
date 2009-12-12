module Savon

  # Savon::WSDL
  #
  # Represents the WSDL document.
  class WSDL

    # Expects a Savon::Request object.
    def initialize(request)
      @request = request
    end

    # Returns the namespace URI from the WSDL.
    def namespace_uri
      @namespace_uri ||= stream.namespace_uri
    end

    # Returns a Hash of available SOAP actions mapped to snake_case (keys)
    # and their original names and inputs in another Hash (values).
    def soap_actions
      @soap_actions ||= stream.soap_actions
    end

    # Returns +true+ for available methods and SOAP actions.
    def respond_to?(method)
      return true if soap_actions.keys.include? method
      super
    end

    # Returns the WSDL document.
    def to_s
      @document ||= @request.wsdl.body
    end

  private

    def stream
      unless @stream
        @stream = WSDLStream.new
        REXML::Document.parse_stream to_s, @stream
      end
      @stream
    end

  end

  # Savon::WSDLStream
  #
  # Stream listener parsing the WSDL document.
  class WSDLStream

    # Sets the initial state.
    def initialize
      @namespace_uri = ""
      @soap_actions = {}
      @wsdl_binding = false
    end

    attr_reader :namespace_uri

    attr_reader :soap_actions
 
    def tag_start(name, attrs)
      @namespace_uri = attrs["targetNamespace"] if name == "wsdl:definitions"
      @wsdl_binding = true if name == "wsdl:binding"
      soap_action(name, attrs) if @wsdl_binding && /.+:operation/ === name
    end

    def soap_action(name, attrs)
      if name == "wsdl:operation"
        @action = attrs["name"]
      elsif /.+:operation/ === name
        @action = attrs["soapAction"] unless attrs["soapAction"].empty?
        input = @action.split("/").last
        @soap_actions[input.snakecase.to_sym] = { :name => @action, :input => input }
      end
    end

    def method_missing(method, *args)
    end

  end
end
