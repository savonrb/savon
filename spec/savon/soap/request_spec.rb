require "spec_helper"

describe Savon::SOAP::Request do
  let(:request) { Savon::SOAP::Request.new HTTPI::Request.new, soap }

  let(:soap) do
    soap = Savon::SOAP::XML.new "getUser", :get_user, Endpoint.soap
    soap.body = { :id => 1 }
    soap
  end

  it "contains the content type for each supported SOAP version" do
    content_type = Savon::SOAP::Request::ContentType
    content_type[1].should == "text/xml;charset=UTF-8"
    content_type[2].should == "application/soap+xml;charset=UTF-8"
  end

  it "should include the Savon::Logger module" do
    Savon::SOAP::Request.ancestors.should include(Savon::Logger)
  end

  describe "#response" do
    it "should use the SOAP endpoint for the request" do
      request.request.url.should == soap.endpoint
    end

    it "should set the 'Content-Type' header for SOAP 1.1" do
      request.request.headers["Content-Type"].should == Savon::SOAP::Request::ContentType[1]
    end

    it "should set the 'Content-Type' header for SOAP 1.2" do
      soap.version = 2
      request.request.headers["Content-Type"].should == Savon::SOAP::Request::ContentType[2]
    end

    it "should not set the 'Content-Type' header if it's already specified" do
      headers = { "Content-Type" => "text/plain" }
      request = Savon::SOAP::Request.new HTTPI::Request.new(:headers => headers), soap
      request.request.headers["Content-Type"].should == headers["Content-Type"]
    end

    it "should set the 'SOAPAction' header" do
      request.request.headers["SOAPAction"].should == soap.action
    end

    it "should not set the 'SOAPAction' header if it's already specified" do
      headers = { "SOAPAction" => "" }
      request = Savon::SOAP::Request.new HTTPI::Request.new(:headers => headers), soap
      request.request.headers["SOAPAction"].should == headers["SOAPAction"]
    end

    it "should set the SOAP body for the request" do
      request.request.body.should == soap.to_xml
    end

    it "should execute an HTTP POST request and return a Savon::SOAP::Response" do
      HTTPI.expects(:post).returns(HTTPI::Response.new 200, {}, ResponseFixture.authentication)
      request.response.should be_a(Savon::SOAP::Response)
    end
  end

end
