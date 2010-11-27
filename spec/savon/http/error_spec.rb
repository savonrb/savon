require "spec_helper"

describe Savon::HTTP::Error do
  let(:http_error) { Savon::HTTP::Error.new new_response(:code => 404, :body => "Not Found") }
  let(:no_error) { Savon::HTTP::Error.new new_response }

  it "should be a Savon::Error" do
    Savon::HTTP::Error.should < Savon::Error
  end

  describe "#http" do
    it "should return the HTTPI::Response" do
      http_error.http.should be_an(HTTPI::Response)
    end
  end

  describe "#present?" do
    it "should return true if there was an HTTP error" do
      http_error.should be_present
    end

    it "should return false unless there was an HTTP error" do
      no_error.should_not be_present
    end
  end

  [:message, :to_s].each do |method|
    describe "##{method}" do
      it "should return an empty String unless an HTTP error is present" do
        no_error.send(method).should == ""
      end

      it "should return the HTTP error message" do
        http_error.send(method).should == "HTTP error (404): Not Found"
      end
    end
  end

  describe "#to_hash" do
    it "should return the HTTP response details as a Hash" do
      http_error.to_hash.should == { :code => 404, :headers => {}, :body => "Not Found" }
    end
  end

  def new_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options
    
    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end

end
