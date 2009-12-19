require "spec_helper"

describe Savon::WSDL do
  before do
    @wsdl = Savon::WSDL.new Savon::Request.new(EndpointHelper.wsdl_endpoint)
  end

  it "is initialized with a Savon::Request object" do
    Savon::WSDL.new Savon::Request.new(EndpointHelper.wsdl_endpoint)
  end

  it "has a getter for the namespace URI" do
    @wsdl.namespace_uri.should == WSDLFixture.authentication(:namespace_uri)
  end

  it "has a getter for returning an Array of available SOAP actions" do
    WSDLFixture.authentication(:soap_actions).each do |soap_action|
      @wsdl.soap_actions.should include soap_action
    end
  end

  it "has a getter for returning a Hash of available SOAP operations" do
    @wsdl.operations.should == WSDLFixture.authentication(:operations)
  end

  it "responds to SOAP actions while still behaving as usual otherwise" do
    valid_soap_action = WSDLFixture.authentication(:soap_actions).first
    @wsdl.respond_to?(valid_soap_action).should be_true

    @wsdl.respond_to?(:object_id).should be_true
    @wsdl.respond_to?(:some_undefined_method).should be_false
  end

  it "returns the raw WSDL document for to_s" do
    @wsdl.to_s.should == WSDLFixture.authentication
  end

end
