require "spec_helper"

describe Savon::Service do
  before { @proxy = Savon::Service.new SpecHelper.some_endpoint }

  describe "method_missing" do

    it "accepts a block for custom response processing" do
      @proxy.find_user { |request| request.body }.should == UserFixture.user_response
    end

    it "parses the SOAP response for a '//return' node and returns the content as a Hash" do
      response = @proxy.find_user

      response.should be_a Hash
      response["id"].should == UserFixture.soap_response_hash_id
      response["username"].should == UserFixture.soap_response_hash_username
      response["email"].should == UserFixture.soap_response_hash_email
      response["registered"].should == UserFixture.soap_response_hash_registered
    end

    it "returns an Array in case of multiple '//return' nodes" do
      proxy = Savon::Service.new SpecHelper.multiple_endpoint
      response = proxy.find_user

      response.should be_an Array
      response[0]["id"].should == UserFixture.soap_response_hash_id
      response[1]["id"].should == UserFixture.soap_response_hash_id2
    end

  end

end