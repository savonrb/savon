require "spec_helper"

describe Savon::WSDL do
  before { @wsdl = some_wsdl_instance }

  def some_wsdl_instance
    Savon::WSDL.new Savon::Request.new SpecHelper.some_endpoint
  end

  describe "initialize" do
    it "expects a Savon::Request object" do
      some_wsdl_instance
    end
  end

  describe "namespace_uri" do
    it "returns the namespace URI from the WSDL" do
      @wsdl.namespace_uri.should == UserFixture.namespace_uri
    end
  end

  describe "soap_actions" do
    it "returns a Hash containing all available SOAP actions, as well as" <<
       "their original names and inputs" do  
      @wsdl.soap_actions.should == UserFixture.soap_actions
    end

    it "raises an ArgumentError in case the WSDL seems to be invalid" do
      wsdl = Savon::WSDL.new Savon::Request.new SpecHelper.invalid_endpoint
      lambda { wsdl.soap_actions }.should raise_error ArgumentError
    end
  end

  describe "respond_to?" do
    it "returns true for available SOAP actions" do
      @wsdl.respond_to?(UserFixture.soap_actions.keys.first).
        should be_true
    end

    it "still behaves like usual otherwise" do
      @wsdl.respond_to?(:object_id).should be_true
      @wsdl.respond_to?(:some_undefined_method).should be_false
    end
  end

  describe "to_s" do
    it "returns the WSDL document" do
      @wsdl.to_s.should == UserFixture.user_wsdl
    end
  end

end