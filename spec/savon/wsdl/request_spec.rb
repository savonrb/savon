require "spec_helper"

describe Savon::WSDL::Request do
  let(:http_request) { HTTPI::Request.new :url => Endpoint.wsdl }
  let(:request) { Savon::WSDL::Request.new http_request }

  describe "#response" do
    it "execute an HTTP GET request and return the HTTPI::Response" do
      response = HTTPI::Response.new 200, {}, ResponseFixture.authentication
      HTTPI.expects(:get).with(http_request).returns(response)
      request.response.should == response
    end
  end

end
