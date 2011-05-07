require "spec_helper"

describe Savon::WSDL::Request do
  let(:http_request) { HTTPI::Request.new :url => Endpoint.wsdl }
  let(:request) { Savon::WSDL::Request.new http_request }

  describe ".execute" do
    it "executes a WSDL request and returns the response" do
      response = HTTPI::Response.new 200, {}, Fixture.response(:authentication)
      HTTPI.expects(:get).with(http_request).returns(response)
      Savon::WSDL::Request.execute(http_request).should == response
    end
  end

  describe "#response" do
    it "executes an HTTP GET request and returns the HTTPI::Response" do
      response = HTTPI::Response.new 200, {}, Fixture.response(:authentication)
      HTTPI.expects(:get).with(http_request).returns(response)
      request.response.should == response
    end
  end

end
