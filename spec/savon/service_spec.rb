require "spec_helper"

describe Savon::Service do
  before { @proxy = Savon::Service.new SpecHelper.some_endpoint }

  describe "SOAPFaultCodeXPath" do
    it "should include the XPath to the SOAP fault code for both SOAP 1+2" do
      Savon::Service::SOAPFaultCodeXPath[1].should be_true
      Savon::Service::SOAPFaultCodeXPath[2].should be_true
    end
  end

  describe "SOAPFaultMessageXPath" do
    it "should include the XPath to the SOAP fault message for both SOAP 1+2" do
      Savon::Service::SOAPFaultMessageXPath[1].should be_true
      Savon::Service::SOAPFaultMessageXPath[2].should be_true
    end
  end

  describe "initialize" do
    it "expects the endpoint URI as a String" do
      Savon::Service.new SpecHelper.some_endpoint
    end

    it "raises" do
      lambda { Savon::Service.new "invalid uri" }.should raise_error(URI::InvalidURIError)
    end
  end

  describe "response" do
    it "returns the Net::HTTPResponse of the last SOAP call" do
      @proxy.find_user
      @proxy.response.should be_a Net::HTTPResponse
    end
  end

  describe "wsdl" do
    it "returns the WSDL object" do
      @proxy.wsdl.should be_an_instance_of Savon::WSDL
    end

    it "always returns the same WSDL object" do 
      @proxy.wsdl.should equal @proxy.wsdl
    end
  end

  describe "respond_to?" do
    it "returns true for SOAP actions" do
      UserFixture.soap_actions.keys.each do |soap_action|
        @proxy.respond_to?(soap_action).should be_true
      end
    end

    it "delegates to super" do
      @proxy.respond_to?(:object_id).should be_true
    end
  end

  describe "method_missing" do
    it "accepts a Hash of parameters to be received by the SOAP service" do
      @proxy.find_user :id => { "$" => "666" }
      @proxy.http_request.body.should include "<id>666</id>"
    end

    describe "Hash configuration per request" do
      it "uses the value from :soap_body for the SOAP request body" do
        @proxy.find_user :soap_body => { :id => { "$" => 666 } }
        @proxy.http_request.body.should include "<id>666</id>"
      end

      it "uses the value from :soap_version to specify the SOAP version" do
        @proxy.find_user :soap_body => {}, :soap_version => 2
        Savon::Config.instance.soap_version.should == 2
      end
    end
  end

end