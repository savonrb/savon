# frozen_string_literal: true
require "spec_helper"
require "integration/support/server"
require "faraday/adapter/test"
require "json"
require "ostruct"

RSpec.describe Savon::Operation do
  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  let(:operation)      { Savon::Operation.create(operation_name, wsdl, globals, transport) }
  let(:operation_name) { :verify_address }
  let(:transport)      { Savon::Transport::HTTPI.new(globals) }
  let(:globals)        { Savon::GlobalOptions.new(endpoint: @server.url(:repeat), log: false) }
  let(:wsdl)           { Wasabi::Document.new Fixture.wsdl(:taxcloud) }
  let(:no_wsdl) do
    Wasabi::Document.new.tap do |doc|
      doc.endpoint  = "http://example.com"
      doc.namespace = "http://v1.example.com"
    end
  end

  describe ".create with a WSDL" do
    it "returns a new operation" do
      expect(operation).to be_a(Savon::Operation)
    end

    context "when the operation name is not a Symbol" do
      let(:operation_name) { "not a symbol" }

      it "raises ArgumentError" do
        expect { operation }.
          to raise_error(ArgumentError, /Expected the first parameter \(the name of the operation to call\) to be a symbol/)
      end
    end

    context "when the operation is not available for the service" do
      let(:operation_name) { :no_such_operation }

      it "raises UnknownOperationError" do
        expect { operation }.
          to raise_error(Savon::UnknownOperationError, /Unable to find SOAP operation: :no_such_operation/)
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
      expect(operation).to be_a(Savon::Operation)
    end
  end

  describe "#build" do
    it "returns the Builder" do
      builder = operation.build(message: { test: "message" })

      expect(builder).to be_a(Savon::Builder)
      expect(builder.to_s).to include("<tns:VerifyAddress><tns:test>message</tns:test></tns:VerifyAddress>")
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

    it "sets Content-Length to the byte size of the body" do
      request = operation.request
      expect(request.headers["Content-Length"]).to eq(request.body.bytesize.to_s)
    end

    it "converts cookies to a Cookie: header on the request" do
      cookies = [HTTPI::Cookie.new("some-cookie=choc-chip")]
      request = operation.request(cookies: cookies)
      expect(request.headers["Cookie"]).to eq("some-cookie=choc-chip")
    end

    context "routing the SOAPAction header" do
      let(:globals) { Savon::GlobalOptions.new(endpoint: @server.url(:inspect_request), log: false) }

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
      let(:globals)        { Savon::GlobalOptions.new(endpoint: @server.url(:multipart), log: false) }
      let(:wsdl)           { no_wsdl }

      it "parses multipart attachments" do
        response = operation.call do
          attachments [
            { filename: "x1.xml", content: "<xml>abc</xml>" },
            { filename: "x2.xml", content: "<xml>cde</xml>" }
          ]
        end

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
  end

  describe "#call with transport: :faraday" do
    let(:stubs)          { ::Faraday::Adapter::Test::Stubs.new }
    let(:connection)     { ::Faraday.new { |f| f.adapter :test, stubs } }
    let(:transport)      { Savon::Transport::Faraday.new(connection, globals) }
    let(:wsdl)           { no_wsdl }
    let(:operation_name) { :authenticate }
    let(:globals) do
      Savon::GlobalOptions.new(
        endpoint:  "http://example.com/soap",
        namespace: "http://v1.example.com",
        transport: :faraday,
        log:       false
      )
    end

    it "routes the request through Transport::Faraday and returns a Savon::Response" do
      stubs.post("/soap") { [200, {}, Fixture.response(:authentication)] }
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
  end

  def inspect_request(response)
    OpenStruct.new JSON.parse(response.http.body)
  end
end
