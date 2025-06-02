# frozen_string_literal: true
require "spec_helper"
require "integration/support/server"
require "json"
require "ostruct"

RSpec.describe Savon::Operation do

  let(:globals) { Savon::GlobalOptions.new(:endpoint => @server.url(:repeat), :log => false) }
  let(:wsdl)    { Wasabi::Document.new Fixture.wsdl(:taxcloud) }

  let(:no_wsdl) {
    wsdl = Wasabi::Document.new

    wsdl.endpoint  = "http://example.com"
    wsdl.namespace = "http://v1.example.com"

    wsdl
  }

  def new_operation(operation_name, wsdl, globals)
    Savon::Operation.create(operation_name, wsdl, globals)
  end

  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  describe ".create with a WSDL" do
    it "returns a new operation" do
      operation = new_operation(:verify_address, wsdl, globals)
      expect(operation).to be_a(Savon::Operation)
    end

    it "raises if the operation name is not a Symbol" do
      expect { new_operation("not a symbol", wsdl, globals) }.
        to raise_error(ArgumentError, /Expected the first parameter \(the name of the operation to call\) to be a symbol/)
    end

    it "raises if the operation is not available for the service" do
      expect { new_operation(:no_such_operation, wsdl, globals) }.
        to raise_error(Savon::UnknownOperationError, /Unable to find SOAP operation: :no_such_operation/)
    end

    it "raises if the endpoint cannot be reached" do
      message = "Error!"
      response = Responses.mock_faraday(500, {}, message)
      error = Wasabi::Resolver::HTTPError.new(message, response)
      Wasabi::Document.any_instance.stubs(:soap_actions).raises(error)

      expect { new_operation(:verify_address, wsdl, globals) }.
        to raise_error(Savon::HTTPError, /#{message}/)
    end
  end

  describe ".create without a WSDL" do
    it "returns a new operation" do
      operation = new_operation(:verify_address, no_wsdl, globals)
      expect(operation).to be_a(Savon::Operation)
    end
  end

  describe "build" do
    it "returns the Builder" do
      operation = new_operation(:verify_address, wsdl, globals)
      builder = operation.build(:message => { :test => 'message' })

      expect(builder).to be_a(Savon::Builder)
      expect(builder.to_s).to include('<tns:VerifyAddress><tns:test>message</tns:test></tns:VerifyAddress>')
    end
  end

  describe "call" do
    it "returns a response object" do
      operation = new_operation(:verify_address, wsdl, globals)
      expect(operation.call).to be_a(Savon::Response)
    end

    it "uses the global :endpoint option for the request" do
      globals.endpoint("http://v1.example.com")

      operation = new_operation(:verify_address, wsdl, globals)
      http_response = Responses.mock_faraday(200, {}, "")
      Faraday::Connection.any_instance.expects(:post).with(globals[:endpoint]).returns(http_response)
      operation.call
    end

    it "falls back to use the WSDL's endpoint if the :endpoint option was not set" do
      globals_without_endpoint = Savon::GlobalOptions.new(:log => false)

      operation = new_operation(:verify_address, wsdl, globals_without_endpoint)

      # stub the actual request
      http_response = Responses.mock_faraday(200, {}, "")
      Faraday::Connection.any_instance.expects(:post).with(wsdl.endpoint).returns(http_response)

      operation.call
    end

    it "sets the Content-Length header" do
      # XXX: probably the worst spec ever written. refactor! [dh, 2013-01-05]
      http_response = Responses.mock_faraday(200, {}, "")

      Faraday::Utils::Headers.any_instance.expects(:[]=).at_least_once
      Faraday::Utils::Headers.any_instance.expects(:[]=).with('Content-Length', "723")
      Faraday::Connection.any_instance.expects(:post).returns(http_response)

      new_operation(:verify_address, wsdl, globals).call
    end

    it "passes the local :soap_action option to the request builder" do
      globals.endpoint @server.url(:inspect_request)
      soap_action = "http://v1.example.com/VerifyAddress"

      operation = new_operation(:verify_address, wsdl, globals)
      response  = operation.call(:soap_action => soap_action)

      actual_soap_action = inspect_request(response).soap_action
      expect(actual_soap_action).to eq(%("#{soap_action}"))
    end

    it "uses the local :cookies option" do
      globals.endpoint @server.url(:inspect_request)
      cookies = {'some-cookie': 'choc-chip'}

      Faraday::Utils::Headers.any_instance.expects(:[]=).at_least_once
      Faraday::Utils::Headers.any_instance.expects(:[]=).with('Cookie', 'some-cookie=choc-chip').at_least_once
      operation = new_operation(:verify_address, wsdl, globals)
      operation.call(:cookies => cookies)
    end

    it "passes nil to the request builder if the :soap_action was set to nil" do
      globals.endpoint @server.url(:inspect_request)

      operation = new_operation(:verify_address, wsdl, globals)
      response  = operation.call(:soap_action => nil)

      actual_soap_action = inspect_request(response).soap_action
      expect(actual_soap_action).to be_nil
    end

    it "gets the SOAP action from the WSDL if available" do
      globals.endpoint @server.url(:inspect_request)

      operation = new_operation(:verify_address, wsdl, globals)
      response  = operation.call

      actual_soap_action = inspect_request(response).soap_action
      expect(actual_soap_action).to eq('"http://taxcloud.net/VerifyAddress"')
    end

    it "falls back to Gyoku if both option and WSDL are not available" do
      globals.endpoint @server.url(:inspect_request)

      operation = new_operation(:authenticate, no_wsdl, globals)
      response  = operation.call

      actual_soap_action = inspect_request(response).soap_action
      expect(actual_soap_action).to eq(%("authenticate"))
    end

    it "handle multipart response" do
      globals.endpoint @server.url(:multipart)
      operation = new_operation(:example, no_wsdl, globals)
      response = operation.call do
        attachments [
          { filename: 'x1.xml', content: '<xml>abc</xml>'},
          { filename: 'x2.xml', content: '<xml>cde</xml>'},
        ]
      end

      expect(response.multipart?).to be true
      expect(response.header).to eq 'response header'
      expect(response.body).to eq 'response body'
      expect(response.attachments.first.content_id).to include('attachment1')
    end

    it "simple request is not multipart" do
      operation = new_operation(:example, no_wsdl, globals)
      response = operation.call

      expect(response.multipart?).to be false
      expect(response.attachments).to be_empty
    end
  end

  describe "request" do
    it "returns the request" do
      operation = new_operation(:verify_address, wsdl, globals)
      request = operation.request

      expect(request.body).to include('<tns:VerifyAddress></tns:VerifyAddress>')
    end
  end

  describe "attachments" do
    context "soap_version 1" do
      it "sends requests with content-type text/xml" do
        globals.endpoint @server.url(:multipart)
        operation = new_operation(:example, no_wsdl, globals)
        req = operation.request do
          attachments [
            { filename: 'x1.xml', content: '<xml>abc</xml>'},
            { filename: 'x2.xml', content: '<xml>cde</xml>'},
          ]
        end
        expect(req.headers["Content-Type"]).to start_with "multipart/related; type=\"text/xml\"; "
      end
    end
    context "soap_version 2" do
      it "sends requests with content-type application/soap+xml" do
        globals.endpoint @server.url(:multipart)
        globals.soap_version 2
        operation = new_operation(:example, no_wsdl, globals)
        req = operation.request do
          attachments [
            { filename: 'x1.xml', content: '<xml>abc</xml>'},
            { filename: 'x2.xml', content: '<xml>cde</xml>'},
          ]
        end
        expect(req.headers["Content-Type"]).to start_with "multipart/related; type=\"application/soap+xml\"; "
      end
    end
    context "MTOM" do
      it "sends request with content-type header application/xop+xml" do
        globals.endpoint @server.url(:multipart)
        operation = new_operation(:example, no_wsdl, globals)
        req = operation.request do
          mtom true
          attachments [
            { filename: 'x1.xml', content: '<xml>abc</xml>'},
            { filename: 'x2.xml', content: '<xml>cde</xml>'},
          ]
        end
        expect(req.headers["Content-Type"]).to start_with "multipart/related; type=\"application/xop+xml\"; start-info=\"text/xml\"; start=\"<soap-request-body@soap>\"; boundary=\"--==_mimepart_"
      end

      it "sends attachments with Content-Transfer-Encoding: binary" do
        globals.endpoint @server.url(:multipart)
        operation = new_operation(:example, no_wsdl, globals)
        req = operation.request do
          mtom true
          attachments [
            { filename: 'x1.xml', content: '<xml>abc</xml>'},
            { filename: 'x2.xml', content: '<xml>cde</xml>'},
          ]
        end
        expect(req.body.to_s).to include("filename=x1.xml\r\nContent-Transfer-Encoding: binary")
      end
      
      it "successfully makes request" do
        globals.endpoint @server.url(:multipart)
        operation = new_operation(:example, no_wsdl, globals)
        response = operation.call do
          mtom true
          attachments [
            { filename: 'x1.xml', content: '<xml>abc</xml>'},
            { filename: 'x2.xml', content: '<xml>cde</xml>'},
          ]
        end

        expect(response.multipart?).to be true
        expect(response.attachments.first.content_id).to include('attachment1')
      end
    end
  end

  def inspect_request(response)
    hash = JSON.parse(response.http.body)
    OpenStruct.new(hash)
  end
end
