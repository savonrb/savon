require "spec_helper"

describe Savon::SOAP::Request do
  let(:soap_request) { Savon::SOAP::Request.new(config, http_request, soap) }
  let(:http_request) { HTTPI::Request.new }
  let(:soap)         { Savon::SOAP::XML.new config, Endpoint.soap, [nil, :get_user, {}], :id => 1 }
  let(:config)       { Savon::Config.default }

  it "contains the content type for each supported SOAP version" do
    content_type = Savon::SOAP::Request::ContentType
    content_type[1].should == "text/xml;charset=UTF-8"
    content_type[2].should == "application/soap+xml;charset=UTF-8"
  end

  describe ".execute" do
    it "executes a SOAP request and returns the response" do
      HTTPI.expects(:post).returns(HTTPI::Response.new 200, {}, Fixture.response(:authentication))
      response = Savon::SOAP::Request.execute config, http_request, soap
      response.should be_a(Savon::SOAP::Response)
    end
  end

  describe ".new" do
    it "uses the SOAP endpoint for the request" do
      soap_request.http.url.should == URI(soap.endpoint)
    end

    it "sets the SOAP body for the request" do
      soap_request.http.body.should == soap.to_xml
    end

    it "sets the Content-Type header for SOAP 1.1" do
      soap_request.http.headers["Content-Type"].should == Savon::SOAP::Request::ContentType[1]
    end

    it "sets the Content-Type header for SOAP 1.2" do
      soap.version = 2
      soap_request.http.headers["Content-Type"].should == Savon::SOAP::Request::ContentType[2]
    end

    it "sets the Content-Length header" do
      soap_request.http.headers["Content-Length"].should == soap.to_xml.length.to_s
    end

    it "sets the Content-Length header for every request" do
      http = HTTPI::Request.new
      soap_request = Savon::SOAP::Request.new(config, http, soap)
      http.headers.should include("Content-Length" => "272")

      soap = Savon::SOAP::XML.new config, Endpoint.soap, [nil, :create_user, {}], :id => 123
      soap_request = Savon::SOAP::Request.new(config, http, soap)
      http.headers.should include("Content-Length" => "280")
    end
  end

  describe "#response" do
    it "executes an HTTP POST request and returns a Savon::SOAP::Response" do
      HTTPI.expects(:post).returns(HTTPI::Response.new 200, {}, Fixture.response(:authentication))
      soap_request.response.should be_a(Savon::SOAP::Response)
    end

    it "logs the filtered SOAP request body" do
      HTTPI.stubs(:post).returns(HTTPI::Response.new 200, {}, "")

      config.logger.stubs(:log).times(2)
      config.logger.expects(:log_filtered).with(soap.to_xml)
      config.logger.stubs(:log).times(2)

      soap_request.response
    end
  end

end
