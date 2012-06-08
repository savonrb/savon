require "spec_helper"

describe Savon::SOAP::Request do

  let(:soap_request)  { Savon::SOAP::Request.new(config, http_request, soap_xml) }
  let(:http_request)  { HTTPI::Request.new }
  let(:http_response) { HTTPI::Response.new 200, {}, Fixture.response(:authentication) }

  let(:config) {
    config = Savon::Config.default
    config.log = false
    config
  }

  def soap_xml(*args)
    @soap_xml ||= soap_xml!(*args)
  end

  def soap_xml!(endpoint = nil, input = nil, body = nil)
    soap = Savon::SOAP::XML.new(config)
    soap.endpoint = endpoint || Endpoint.soap
    soap.input    = input    || [nil, :get_user, {}]
    soap.body     = body     || { :id => 1 }
    soap
  end

  it "contains the content type for each supported SOAP version" do
    content_type = Savon::SOAP::Request::CONTENT_TYPE
    content_type[1].should == "text/xml;charset=UTF-8"
    content_type[2].should == "application/soap+xml;charset=UTF-8"
  end

  describe ".execute" do
    it "executes a SOAP request and returns the response" do
      HTTPI.expects(:post).returns(http_response)
      response = Savon::SOAP::Request.execute config, http_request, soap_xml
      response.should be_a(Savon::SOAP::Response)
    end
  end

  describe ".new" do
    it "uses the SOAP endpoint for the request" do
      soap_request.http.url.should == URI(soap_xml.endpoint)
    end

    it "sets the SOAP body for the request" do
      soap_request.http.body.should == soap_xml.to_xml
    end

    it "sets the Content-Type header for SOAP 1.1" do
      soap_request.http.headers["Content-Type"].should == Savon::SOAP::Request::CONTENT_TYPE[1]
    end

    it "sets the Content-Type header for SOAP 1.2" do
      soap_xml.version = 2
      soap_request.http.headers["Content-Type"].should == Savon::SOAP::Request::CONTENT_TYPE[2]
    end

    it "sets the Content-Length header" do
      soap_request.http.headers["Content-Length"].should == soap_xml.to_xml.length.to_s
    end

    it "sets the Content-Length header for every request" do
      http = HTTPI::Request.new
      soap_request = Savon::SOAP::Request.new(config, http, soap_xml)
      http.headers.should include("Content-Length" => "272")

      soap_xml = soap_xml!(Endpoint.soap, [nil, :create_user, {}], :id => 123)
      soap_request = Savon::SOAP::Request.new(config, http, soap_xml)
      http.headers.should include("Content-Length" => "280")
    end
  end

  describe "#response" do
    it "executes an HTTP POST request and returns a Savon::SOAP::Response" do
      HTTPI.expects(:post).returns(http_response)
      soap_request.response.should be_a(Savon::SOAP::Response)
    end

    context "with a :soap_request hook" do
      it "lets you replace the HTTP request and return your own response" do
        config.hooks.define(:test, :soap_request) do |_, request|
          request.should be_a(Savon::SOAP::Request)
          http_response
        end

        response = soap_request.response
        response.http.should equal(http_response)
      end

      it "works as an around filter for the SOAP request" do
        HTTPI.expects(:post).returns(http_response)
        state = []

        config.hooks.define(:test, :soap_request) do |callback, request|
          state << :before
          response = callback.call
          state << response
          state << :after
          response
        end

        response = soap_request.response

        state[0].should == :before
        state[1].should be_a(HTTPI::Response)
        state[2].should == :after
      end
    end
  end

end
