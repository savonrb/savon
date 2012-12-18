require "spec_helper"
require "integration/support/server"

describe Savon::Request do

  subject(:request) { Savon::Request.new(:authenticate, wsdl, globals, locals) }

  let(:globals)     { Savon::GlobalOptions.new(:endpoint => @server.url, :log => false) }
  let(:locals)      { Savon::LocalOptions.new }
  let(:wsdl)        { Wasabi::Document.new Fixture.wsdl(:authentication) }
  let(:no_wsdl)     { Wasabi::Document.new }

  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  describe "#call" do
    it "expects the XML to POST" do
      response = request.call("<xml/>")

      expect(request.http.url).to eq(URI(globals[:endpoint]))
      expect(request.http.body).to eq("<xml/>")
      expect(request.http.headers["Content-Length"]).to eq("<xml/>".bytesize.to_s)

      expect(response).to be_a(HTTPI::Response)
    end

    it "falls back to use the WSDL's endpoint if the global :endpoint option was not set" do
      wsdl.endpoint = @server.url
      globals_without_endpoint = Savon::GlobalOptions.new(:log => false)
      request = Savon::Request.new(:authenticate, wsdl, globals_without_endpoint, locals)
      response = request.call("<xml/>")

      expect(request.http.url).to eq(URI(wsdl.endpoint))
    end

    it "sets the global :proxy option if it's available" do
      globals[:proxy] = "http://proxy.example.com"
      expect(request.http.proxy).to eq(URI(globals[:proxy]))
    end

    it "does not set the global :proxy option when it's not available" do
      expect(request.http.proxy).to be_nil
    end

    it "sets the request cookies using the global :last_response option if it's available" do
      http = HTTPI::Response.new(200, {}, ["<success/>"])
      globals[:last_response] = Savon::Response.new(http, globals, locals)

      HTTPI::Request.any_instance.expects(:set_cookies).with(globals[:last_response]).once
      request
    end

    it "does not set the cookies using the global :last_response option when it's not available" do
      expect(request.http.open_timeout).to be_nil
    end

    it "sets the global :open_timeout option if it's available" do
      globals[:open_timeout] = 33
      expect(request.http.open_timeout).to eq(globals[:open_timeout])
    end

    it "does not set the global :open_timeout option when it's not available" do
      request.call("<xml/>")
      expect(request.http.open_timeout).to be_nil
    end

    it "sets the global :read_timeout option if it's available" do
      globals[:read_timeout] = 44
      expect(request.http.read_timeout).to eq(globals[:read_timeout])
    end

    it "does not set the global :read_timeout option when it's not available" do
      expect(request.http.read_timeout).to be_nil
    end

    it "sets the global :headers option if it's available" do
      globals[:headers] = { "X-Authorize" => "secret" }
      expect(request.http.headers["X-Authorize"]).to eq("secret")
    end

    it "sets the SOAPAction header using the local :soap_action option if it's available" do
      locals[:soap_action] = "urn://authenticate"
      expect(request.http.headers["SOAPAction"]).to eq(%{"#{locals[:soap_action]}"})
    end

    it "sets the SOAPAction header using the WSDL if it's available" do
      expect(request.http.headers["SOAPAction"]).to eq(%{"authenticate"})
    end

    it "sets the SOAPAction header using Gyoku if both option and WSDL were not set" do
      request = Savon::Request.new(:authenticate, no_wsdl, globals, locals)
      expect(request.http.headers["SOAPAction"]).to eq(%{"authenticate"})
    end

    it "does not set the SOAPAction header if it's already set" do
      locals[:soap_action] = "urn://authenticate"
      globals[:headers] = { "SOAPAction" => %{"doAuthenticate"} }

      expect(request.http.headers["SOAPAction"]).to eq(%{"doAuthenticate"})
    end

    it "does not set the SOAPAction header if the local :soap_action was set to nil" do
      locals[:soap_action] = nil
      expect(request.http.headers).to_not include("SOAPAction")
    end

    it "sets the SOAP 1.2 Content-Type header using the global :soap_version and :encoding options if available" do
      globals[:soap_version] = 2
      globals[:encoding] = "UTF-16"

      expect(request.http.headers["Content-Type"]).to eq("application/soap+xml;charset=UTF-16")
    end

    it "sets the SOAP 1.1 Content-Type header using the global :soap_version and :encoding options if available" do
      globals[:soap_version] = 1
      globals[:encoding] = "UTF-8"

      expect(request.http.headers["Content-Type"]).to eq("text/xml;charset=UTF-8")
    end

    it "sets the global :basic_auth option if it's available" do
      globals[:basic_auth] = [:luke, "secret"]
      expect(request.http.auth.basic).to eq(globals[:basic_auth])
    end

    it "does not set the global :basic_auth option when it's not available" do
      expect(request.http.auth.basic).to be_nil
    end

    it "sets the global :digest_auth option if it's available" do
      globals[:digest_auth] = [:lea, "top-secret"]
      expect(request.http.auth.digest).to eq(globals[:digest_auth])
    end

    it "does not set the global :digest_auth option when it's not available" do
      expect(request.http.auth.digest).to be_nil
    end
  end

end
