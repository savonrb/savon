require "basic_spec_helper"

describe Savon do
  before { @endpoint = "http://localhost:8080/http-basic-auth" }

  it "should be able to handle HTTP basic authentication" do
    client = Savon::Client.new @endpoint
    client.request.basic_auth "user", "password"
    response = client.do_something!
    response.to_hash[:authenticate_response][:return][:success].should == true
  end
end
