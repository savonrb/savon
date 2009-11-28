require "spec_helper"

describe Savon::Client do
  before { @client = Savon::Client.new SpecHelper.some_endpoint }

  describe "@response_process" do
    it "expects a Net::HTTPResponse, translates the response" <<
       "into a Hash and returns the SOAP response body" do
      response = Savon::Client.response_process.call(http_response_mock)

      response.should be_a Hash
      UserFixture.response_hash.each do |key, value|
        response[key].should == value
      end
    end
  end

  def http_response_mock
    unless @http_response_mock
      @http_response_mock = mock "Net::HTTPResponse"
      @http_response_mock.stubs :code => "200", :message => "OK",
        :content_type => "text/html", :body => UserFixture.user_response
    end
    @http_response_mock
  end

end
