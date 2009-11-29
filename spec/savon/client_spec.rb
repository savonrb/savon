require "spec_helper"

describe Savon::Client do
  before { @client = new_client_instance }

  def new_client_instance
    Savon::Client.new SpecHelper.some_endpoint
  end

  describe "@response_process" do
    it "expects a Net::HTTPResponse, translates the response" <<
       "into a Hash and returns the SOAP response body" do
      response = Savon::Client.response_process.call(http_response_mock)

      response.should be_a Hash
      UserFixture.response_hash.each do |key, value|
        response[key].should == value
      end
    end

    it "has accessor methods" do
      response_process = Savon::Client.response_process

      Savon::Client.response_process = "process"
      Savon::Client.response_process.should == "process"
      Savon::Client.response_process = response_process
      Savon::Client.response_process.should == response_process
    end
  end

  describe "initialize" do
    it "expects a SOAP endpoint String" do
      new_client_instance
    end

    it "raises an ArgumentError in case of an invalid endpoint" do
      lambda { Savon::Client.new "invalid" }.should raise_error ArgumentError
    end
  end

  describe "wsdl" do
    it "returns the Savon::WSDL" do
      @client.find_user

      @client.wsdl.should be_a Savon::WSDL
      @client.wsdl.to_s.should == UserFixture.user_wsdl
    end
  end
  
  describe "response" do
    it "returns the Net::HTTPResponse of the last SOAP request" do
      @client.find_user

      @client.response.should be_a Net::HTTPResponse
      @client.response.body.should == UserFixture.user_response
    end
  end

  describe "respond_to?" do
    it "returns true for available SOAP actions" do
      @client.respond_to?(UserFixture.soap_actions.keys.first).
        should be_true
    end

    it "still behaves like usual otherwise" do
      @client.respond_to?(:object_id).should be_true
      @client.respond_to?(:some_missing_method).should be_false
    end
  end

  describe "method_missing" do
    it "dispatches SOAP requests for available SOAP actions" do
      @client.find_user.should be_a Hash
    end

    it "still returns a NoMethodError for missing methods" do
      lambda { @client.some_missing_method }.should raise_error NoMethodError
    end

    it "accepts a Hash for specifying the SOAP body" do
      soap_body_hash = { :id => 666 }
      @client.find_user soap_body_hash

      @client.instance_variable_get("@soap").body.
        should include soap_body_hash.to_soap_xml
    end

    it "accepts a String for specifying the SOAP body" do
      soap_body_xml = "<username>dude</username>"
      @client.find_user soap_body_xml

      @client.instance_variable_get("@soap").body.
        should include soap_body_xml
    end

    describe "accepts a Hash of per request options" do
      it "to specify the SOAP version" do
        @client.find_user nil, :soap_version => 2
        @client.instance_variable_get("@soap").version.should == 2
      end

      it "to specify credentials for WSSE authentication" do
        @client.find_user nil, :wsse =>
          { :username => "gorilla", :password => "secret" }

        @client.instance_variable_get("@soap").body.should include "gorilla"
        @client.instance_variable_get("@soap").body.should include "secret"
      end

      it "to specify credentials for WSSE digestauthentication" do
        @client.find_user nil, :wsse =>
          { :username => "gorilla", :password => "secret", :digest => true }

        @client.instance_variable_get("@soap").body.should include "gorilla"
        @client.instance_variable_get("@soap").body.should_not include "secret"
      end
    end

    it "accepts a block for specifying the response process per request" do
      @client.find_user { |response| response.body }.
        should == UserFixture.user_response
    end

    it "raises a Savon::SOAPFault in case of a SOAP fault" do
      client = Savon::Client.new SpecHelper.soapfault_endpoint
      lambda { client.find_user }.should raise_error Savon::SOAPFault
    end

    it "raises a Savon::HTTPError in case of an HTTP error" do
      client = Savon::Client.new SpecHelper.httperror_endpoint
      lambda { client.find_user }.should raise_error Savon::HTTPError
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
