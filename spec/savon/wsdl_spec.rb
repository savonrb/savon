require "spec_helper"

describe Savon::WSDL do
  before { @wsdl = Savon::WSDL.new SpecHelper.some_endpoint_uri }

  describe "initialize" do
    it "expects a URI object of the endpoint" do
      Savon::WSDL.new SpecHelper.some_endpoint_uri
    end
  end

  describe "namespace_uri" do
    it "returns the namespace URI from the WSDL" do
      @wsdl.namespace_uri.should == UserFixture.namespace_uri
    end
  end

  describe "soap_actions" do
    it "returns an Array containing all available SOAP actions" do
      @wsdl.soap_actions.should == UserFixture.soap_actions.keys
    end
  end

  describe "soap_action_for" do
    it "returns the name of a SOAP action for a snake_case alias" do
      UserFixture.soap_actions.each do |key, value|
        @wsdl.soap_action_for(key).should == value
      end
    end
  end

  describe "to_s" do
    it "returns the WSDL document" do
      @wsdl.to_s.should == UserFixture.user_wsdl
    end
  end

end