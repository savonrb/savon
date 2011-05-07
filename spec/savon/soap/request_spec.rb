require "spec_helper"

describe Savon::SOAP::Request do
  let(:request) { Savon::SOAP::Request.new HTTPI::Request.new, soap }
  let(:soap) { Savon::SOAP::XML.new Endpoint.soap, :get_user, :id => 1 }

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
      request.request.url.should == URI(soap.endpoint)
    end

    it "sets the SOAP body for the request" do
      request.request.body.should == soap.to_xml
    end

    it "sets the 'Content-Type' header for SOAP 1.1" do
      request.request.headers["Content-Type"].should == Savon::SOAP::Request::ContentType[1]
    end

    it "sets the 'Content-Type' header for SOAP 1.2" do
      soap.version = 2
      request.request.headers["Content-Type"].should == Savon::SOAP::Request::ContentType[2]
    end

    it "does not set the 'Content-Type' header if it's already specified" do
      headers = { "Content-Type" => "text/plain" }
      request = Savon::SOAP::Request.new HTTPI::Request.new(:headers => headers), soap
      request.request.headers["Content-Type"].should == headers["Content-Type"]
    end
  end

  describe "#response" do
    it "executes an HTTP POST request and returns a Savon::SOAP::Response" do
      HTTPI.expects(:post).returns(HTTPI::Response.new 200, {}, Fixture.response(:authentication))
      request.response.should be_a(Savon::SOAP::Response)
    end
  end

end
