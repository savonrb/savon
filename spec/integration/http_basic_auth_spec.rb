require "basic_spec_helper"

describe Savon do
  before { @client = Savon::Client.new "http://localhost:8080/http-basic-auth" }

  it "should be able to handle HTTP basic authentication" do
    @client.request.basic_auth "user", "password"
    response = @client.do_something!
    response.to_hash[:authenticate_response][:return][:success].should == true
  end

  it "should raise a Savon::HTTPError in case authentication failed" do
    lambda { @client.do_something! }.should raise_error(Savon::HTTPError)
  end

end
