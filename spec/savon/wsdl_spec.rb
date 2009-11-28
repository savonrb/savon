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
      @wsdl.soap_actions.should == UserFixture.soap_actions.keys
    end
  end

  describe "mapped_soap_actions" do
   it "returns a Hash containing all available SOAP actions and their original names" do
      @wsdl.mapped_soap_actions.should == UserFixture.soap_actions
    end
  end

  describe "to_s" do
    it "returns the WSDL document" do
      @wsdl.to_s.should == UserFixture.user_wsdl
    end
  end

end