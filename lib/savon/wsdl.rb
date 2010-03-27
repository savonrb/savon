module Savon

  # = Savon::WSDL
  #
  # Savon::WSDL represents the WSDL of your service, including information like the namespace URI,
  # the SOAP endpoint and available SOAP actions.
  #
  # == The WSDL document
  #
  # Retrieve the raw WSDL document:
  #
  #   client.wsdl.to_s
  #
  # == Available SOAP actions
  #
  # Get an array of available SOAP actions:
  #
  #   client.wsdl.soap_actions
  #   # => [:get_all_users, :get_user_by_id]
  #
  # == Namespace URI
  #
  # Get the namespace URI:
  #
  #   client.wsdl.namespace_uri
  #   # => "http://ws.userservice.example.com"
  #
  # == SOAP endpoint
  #
  # Get the SOAP endpoint:
  #
  #   client.wsdl.soap_endpoint
  #   # => "http://example.com"
  #
  # == Disable Savon::WSDL
  #
  # Especially with large services (i.e. Ebay), getting and parsing the WSDL document can really
  # slow down your request. The WSDL is great for exploring a service, but it's recommended to
  # disable it for production.
  #
  # When disabling the WSDL, you need to pay attention to certain differences:
  #
  # 1. You instantiate Savon::Client with the actual SOAP endpoint instead of pointing it to the
  #    WSDL of your service.
  # 2. You also need to manually specify the SOAP.namespace.
  # 3. Append an exclamation mark (!) to your SOAP call:
  #
  #   client = Savon::Client.new "http://example.com"
  #
  #   client.get_user_by_id! do |soap|
  #     soap.namespace = "http://example.com/UserService"
  #     soap.body = { :id => 666 }
  #   end
  #
  # Without the WSDL, Savon also has to guess the name of the SOAP action and input tag. It takes
  # the name of the method called on its client instance, converts it from snake_case to lowerCamelCase
  # and uses the result.
  #
  # The example above expects a SOAP action with an original name of "getUserById". If you service
  # uses UpperCamelCase method names, you can just use the original name:
  #
  #   client.GetAllUsers!
  #
  # For special cases, you could also specify the SOAP.action and SOAP.input inside the block:
  #
  #   client.get_user_by_id! do |soap|
  #     soap.namespace = "http://example.com/UserService"
  #     soap.action = "GetUserById"
  #     soap.input = "GetUserByIdRequest"
  #     soap.body = { :id => 123 }
  #   end
  class WSDL

    # Expects a Savon::Request and accepts a custom +soap_endpoint+.
    def initialize(request, soap_endpoint = nil)
      @request, @enabled, @soap_endpoint = request, true, soap_endpoint
    end

    # Sets whether to use the WSDL.
    attr_writer :enabled

    # Returns whether to use the WSDL. Defaults to +true+.
    def enabled?
      @enabled
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
      return true if !enabled? || soap_actions.include?(method)
      super
    end

    # Returns an Array containg the SOAP action and input for a given +soap_call+.
    def operation_from(soap_action)
      return [soap_action.to_soap_key, soap_action.to_soap_key] unless enabled?
      [operations[soap_action][:action], operations[soap_action][:input]]
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
