# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"
require "faraday/adapter/test"
require "json"
require "ostruct"

RSpec.describe Savon::Operation do
  let(:operation)      { described_class.create(operation_name, wsdl, globals, transport) }
  let(:operation_name) { :verify_address }
  let(:transport)      { Savon::Transport::HTTPI.new(globals) }
  let(:globals)        { Savon::GlobalOptions.new(endpoint: integration_server.url(:repeat), log: false) }
  let(:wsdl)           { Wasabi::Document.new Fixture.wsdl(:taxcloud) }
  let(:no_wsdl) do
    Wasabi::Document.new.tap do |doc|
      doc.endpoint  = "http://example.com"
      doc.namespace = "http://v1.example.com"
    end
  end

  describe ".create with a WSDL" do
    it "returns a new operation" do
      expect(operation).to be_a(described_class)
    end

    context "when the operation name is not a Symbol" do
      let(:operation_name) { "not a symbol" }

      it "raises ArgumentError" do
        expect { operation }
          .to raise_error(ArgumentError, /Expected the first parameter \(the name of the operation to call\) to be a symbol/)
      end
    end

    context "when the operation is not available for the service" do
      let(:operation_name) { :no_such_operation }

      it "raises UnknownOperationError" do
        expect { operation }
          .to raise_error(Savon::UnknownOperationError, /Unable to find SOAP operation: :no_such_operation/)
      end
    end

    context "when the endpoint cannot be reached" do
      before do
        message  = "Error!"
        response = HTTPI::Response.new(500, {}, message)
        error    = Wasabi::Resolver::HTTPError.new(message, response)
        Wasabi::Document.any_instance.stubs(:soap_actions).raises(error)
      end

      it "raises HTTPError" do
        expect { operation }.to raise_error(Savon::HTTPError, /Error!/)
      end
    end
  end

  describe ".create without a WSDL" do
    let(:wsdl) { no_wsdl }

    it "returns a new operation" do
      expect(operation).to be_a(described_class)
    end
  end

  describe "#build" do
    it "returns the Builder" do
      builder = operation.build(message: { test: "message" })

      expect(builder).to be_a(Savon::Builder)
      expect(builder.to_s).to include("<tns:VerifyAddress><tns:test>message</tns:test></tns:VerifyAddress>")
    end

    # With use_wsa_headers and no explicit :soap_action/:endpoint,
    # WSA headers must be populated from the WSDL.
    context "with use_wsa_headers and no explicit soap_action or endpoint" do
      let(:globals) { Savon::GlobalOptions.new(log: false, use_wsa_headers: true) }

      it "populates wsa:Action from the WSDL soapAction" do
        xml = operation.build(message: {}).to_s

        expect(xml).to include("<wsa:Action>http://taxcloud.net/VerifyAddress</wsa:Action>")
      end

      it "populates wsa:To from the WSDL endpoint" do
        xml = operation.build(message: {}).to_s

        expect(xml).to include("<wsa:To>https://api.taxcloud.net/1.0/TaxCloud.asmx</wsa:To>")
      end

      it "does not emit nil WSA headers" do
        xml = operation.build(message: {}).to_s

        expect(xml).not_to include('xsi:nil="true"')
      end
    end

    # Explicit :soap_action/:endpoint must take precedence
    # over the WSDL when populating the WSA headers.
    context "with use_wsa_headers and explicit soap_action and endpoint" do
      let(:globals) do
        Savon::GlobalOptions.new(log: false, use_wsa_headers: true, endpoint: "http://explicit.example.com/service")
      end

      it "uses the explicit soap_action for wsa:Action" do
        xml = operation.build(message: {}, soap_action: "http://explicit.example.com/Action").to_s

        expect(xml).to include("<wsa:Action>http://explicit.example.com/Action</wsa:Action>")
      end

      it "uses the explicit endpoint for wsa:To" do
        xml = operation.build(message: {}).to_s

        expect(xml).to include("<wsa:To>http://explicit.example.com/service</wsa:To>")
      end
    end

    # Without use_wsa_headers, no WS-Addressing namespace or headers are emitted.
    context "without use_wsa_headers" do
      let(:globals) { Savon::GlobalOptions.new(log: false) }

      it "emits no WSA namespace or headers" do
        xml = operation.build(message: {}).to_s

        expect(xml).not_to include("xmlns:wsa")
        expect(xml).not_to include("<wsa:Action")
        expect(xml).not_to include("<wsa:To")
      end
    end
  end

  describe "#call" do
    it "returns a response object whose http is a Transport::Response" do
      response = operation.call
      expect(response).to be_a(Savon::Response)
      expect(response.http).to be_a(Savon::Transport::Response)
    end

    context "when an endpoint is set via globals" do
      let(:globals) { Savon::GlobalOptions.new(endpoint: "http://v1.example.com", log: false) }

      it "uses the global :endpoint option for the request" do
        expect(operation.request.url.to_s).to eq("http://v1.example.com")
      end
    end

    context "when no endpoint is set via globals" do
      let(:globals) { Savon::GlobalOptions.new(log: false) }

      it "falls back to use the WSDL's endpoint" do
        expect(operation.request.url.to_s).to eq(wsdl.endpoint.to_s)
      end
    end

    context "when verifying Content-Length via the HTTPI adapter" do
      let(:globals) { Savon::GlobalOptions.new(endpoint: integration_server.url(:inspect_request), log: false) }

      it "sends the exact Content-Length on the wire (via the HTTPI adapter)" do
        data = inspect_request(operation.call)
        expect(data.content_length).to match(/\A\d+\z/), "expected a single integer not multiple values"
        expect(data.content_length).to eq(data.body_bytesize)
      end
    end

    it "converts cookies to a Cookie: header on the request" do
      cookies = [HTTPI::Cookie.new("some-cookie=choc-chip")]
      request = operation.request(cookies: cookies)
      expect(request.headers["Cookie"]).to eq("some-cookie=choc-chip")
    end

    context "routing the SOAPAction header" do
      let(:globals) { Savon::GlobalOptions.new(endpoint: integration_server.url(:inspect_request), log: false) }

      it "passes the local :soap_action option to the request builder" do
        soap_action = "http://v1.example.com/VerifyAddress"
        response    = operation.call(soap_action: soap_action)
        expect(inspect_request(response).soap_action).to eq(%("#{soap_action}"))
      end

      it "passes nil if :soap_action is explicitly set to nil" do
        response = operation.call(soap_action: nil)
        expect(inspect_request(response).soap_action).to be_nil
      end

      it "gets the SOAP action from the WSDL" do
        expect(inspect_request(operation.call).soap_action).to eq('"http://taxcloud.net/VerifyAddress"')
      end

      context "without a WSDL" do
        let(:operation_name) { :authenticate }
        let(:wsdl)           { no_wsdl }

        it "falls back to Gyoku" do
          expect(inspect_request(operation.call).soap_action).to eq(%("authenticate"))
        end
      end
    end

    context "with a multipart response" do
      let(:operation_name) { :example }
      let(:globals)        { Savon::GlobalOptions.new(endpoint: integration_server.url(:multipart), log: false) }
      let(:wsdl)           { no_wsdl }

      it "parses multipart attachments" do
        response = operation.call {
          attachments [
            { filename: "x1.xml", content: "<xml>abc</xml>" },
            { filename: "x2.xml", content: "<xml>cde</xml>" }
          ]
        }

        expect(response.multipart?).to be true
        expect(response.header).to eq "response header"
        expect(response.body).to eq "response body"
        expect(response.attachments.first.content_id).to include("attachment1")
      end
    end

    context "without a multipart response" do
      let(:operation_name) { :example }
      let(:wsdl)           { no_wsdl }

      it "response is not multipart" do
        response = operation.call
        expect(response.multipart?).to be false
        expect(response.attachments).to be_empty
      end
    end

    context "with attachments" do
      let(:globals) { Savon::GlobalOptions.new(endpoint: integration_server.url(:inspect_request), log: false) }

      it "sends a multipart/related Content-Type" do
        response = operation.call {
          attachments [{ filename: "x1.xml", content: "<xml>abc</xml>" }]
        }

        expect(inspect_request(response).content_type).to start_with("multipart/related;")
      end
    end
  end

  describe "#call with transport: :faraday" do
    let(:stubs)          { ::Faraday::Adapter::Test::Stubs.new }
    let(:connection)     { ::Faraday.new { |f| f.adapter :test, stubs } }
    let(:transport)      { Savon::Transport::Faraday.new(connection, globals) }
    let(:wsdl)           { no_wsdl }
    let(:operation_name) { :authenticate }
    let(:globals) do
      Savon::GlobalOptions.new(
        endpoint: "http://example.com/soap",
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
    end

    it "routes the request through Transport::Faraday and returns a Savon::Response" do
      stubs.post("/soap") do [200, {}, Fixture.response(:authentication)] end
      response = operation.call
      expect(response).to be_a(Savon::Response)
      expect(response.http).to be_a(Savon::Transport::Response)
    end

    it "sends the SOAP body through the Faraday connection" do
      captured = nil
      stubs.post("/soap") do |env|
        captured = env.body
        [200, {}, Fixture.response(:authentication)]
      end
      operation.call
      expect(captured).to include("authenticate")
    end

    it "raises ArgumentError for #request since it is httpi-specific" do
      expect { operation.request }.to raise_error(ArgumentError, /#request.*not supported.*transport: :faraday/m)
    end
  end

  describe "#request" do
    it "returns an HTTPI::Request with the XML body" do
      request = operation.request
      expect(request).to be_a(HTTPI::Request)
      expect(request.body).to include("<tns:VerifyAddress></tns:VerifyAddress>")
    end

    context "with attachments" do
      # Regression: the 2.17.0 transport refactor assembled request headers
      # before the multipart body was built, so Builder#multipart was empty at
      # header time and the request went out as plain text/xml.
      it "sets a multipart/related Content-Type carrying the body's MIME boundary" do
        request = operation.request {
          attachments [{ filename: "x1.xml", content: "<xml>abc</xml>" }]
        }

        content_type = request.headers["Content-Type"]
        expect(content_type).to start_with("multipart/related;")

        boundary = content_type[/boundary="([^"]+)"/, 1]
        expect(boundary).not_to be_nil
        expect(request.body).to include("--#{boundary}")
      end
    end
  end

  def inspect_request(response)
    OpenStruct.new JSON.parse(response.http.body)
  end
end
