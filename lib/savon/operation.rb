require 'savon/response'
require 'savon/envelope'
require 'savon/example_message'

class Savon
  class Operation

    ENCODING = 'UTF-8'

    CONTENT_TYPE = {
      '1.1' => 'text/xml;charset=%s',
      '1.2' => 'application/soap+xml;charset=%s'
    }

    def initialize(operation, wsdl, http)
      @operation = operation
      @wsdl = wsdl
      @http = http

      @endpoint = operation.endpoint
      @soap_version = operation.soap_version
      @soap_action = operation.soap_action
      @encoding = ENCODING
    end

    # Public: Accessor for the SOAP endpoint.
    attr_accessor :endpoint

    # Public: Accessor for the SOAP version.
    attr_accessor :soap_version

    # Public: Accessor for the SOAPAction HTTP header.
    attr_accessor :soap_action

    # Public: Accessor for the encoding. Defaults to 'UTF-8'.
    attr_accessor :encoding

    # Public: Returns a Hash of HTTP headers to send.
    def headers
      return @headers if @headers
      headers = {}

      headers['SOAPAction']   = %{"#{soap_action}"} if soap_action
      headers['Content-Type'] = CONTENT_TYPE[soap_version] % encoding

      @headers = headers
    end

    # Public: Sets the Hash of HTTP headers.
    attr_writer :headers

    # Public: Sets the request body Hash.
    attr_accessor :body

    # Public: Create an example request body Hash.
    def example_body
      ExampleMessage.new(@operation.input).to_hash
    end

    # Public: Build the request XML for this operation.
    def build
      Envelope.new(@operation, body).to_s
    end

    # Public: Call the operation.
    def call
      raw_response = @http.post(endpoint, headers, build)
      Response.new(raw_response)
    end

    # Public: Returns the input parts.
    def input_parts
      @operation.input.inject([]) { |memo, part| memo + part.to_a }
    end

    # Public: Returns the input style for this operation.
    def input_style
      @input_style ||= @operation.input_style
    end

    # Public: Returns the output style for this operation.
    def output_style
      @output_style ||= @operation.output_style
    end

  end
end
