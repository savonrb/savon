require "spec_helper"

describe Savon::SOAP::Request do
  let(:soap_request) { Savon::SOAP::Request.new HTTPI::Request.new, soap }
  let(:soap) { Savon::SOAP::XML.new Endpoint.soap, [nil, :get_user, {}], :id => 1 }

  it "contains the content type for each supported SOAP version" do
    content_type = Savon::SOAP::Request::ContentType
    content_type[1].should == "text/xml;charset=UTF-8"
    content_type[2].should == "application/soap+xml;charset=UTF-8"
  end

  describe ".execute" do
    it "executes a SOAP request and returns the response" do
      HTTPI.expects(:post).returns(HTTPI::Response.new 200, {}, Fixture.response(:authentication))
      response = Savon::SOAP::Request.execute HTTPI::Request.new, soap
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

    it "does not set the Content-Type header if it's already specified" do
      headers = { "Content-Type" => "text/plain" }
      soap_request = Savon::SOAP::Request.new HTTPI::Request.new(:headers => headers), soap
      soap_request.http.headers["Content-Type"].should == headers["Content-Type"]
    end

    it "sets the Content-Length header" do
      soap_request.http.headers["Content-Length"].should == soap.to_xml.length.to_s
    end
  end

  describe "#response" do
    it "executes an HTTP POST request and returns a Savon::SOAP::Response" do
      HTTPI.expects(:post).returns(HTTPI::Response.new 200, {}, Fixture.response(:authentication))
      soap_request.response.should be_a(Savon::SOAP::Response)
    end

    it "logs the filtered SOAP request body" do
      HTTPI.stubs(:post).returns(HTTPI::Response.new 200, {}, "")

      Savon.stubs(:log).times(2)
      Savon.expects(:log).with(soap.to_xml, :filter)
      Savon.stubs(:log).times(2)

      soap_request.response
    end
  end

end
