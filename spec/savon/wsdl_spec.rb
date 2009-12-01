require "spec_helper"

describe Savon::WSDL do
  before { @wsdl = Savon::WSDL.new Savon::Request.new SpecHelper.some_endpoint }

  describe "initialize" do
    it "expects a Savon::Request object" do
      Savon::WSDL.new Savon::Request.new SpecHelper.some_endpoint
    end
  end

  describe "namespace_uri" do
    it "returns the namespace URI from the WSDL" do
      @wsdl.namespace_uri.should == UserFixture.namespace_uri
    end
  end

  describe "soap_actions" do
    it "returns an Array containing all available SOAP actions" do
      @wsdl.soap_actions.should == UserFixture.soap_action_map.keys
    end

    it "raises an ArgumentError in case the WSDL seems to be invalid" do
      wsdl = Savon::WSDL.new Savon::Request.new SpecHelper.invalid_endpoint
      lambda { wsdl.soap_actions }.should raise_error ArgumentError
    end
  end

  describe "soap_action_map" do
    it "returns a Hash containing all available SOAP actions, as well as" <<
       "their original names and inputs" do  
      @wsdl.soap_action_map.should == UserFixture.soap_action_map
    end
  end

  describe "to_s" do
    it "returns the WSDL document" do
      @wsdl.to_s.should == UserFixture.user_wsdl
    end
  end

end
