require "spec_helper"

describe Savon::Client do
  before { @client = Savon::Client.new EndpointHelper.wsdl_endpoint }

  it "is initialized with a SOAP endpoint String" do
    Savon::Client.new EndpointHelper.wsdl_endpoint
  end

  it "raises an ArgumentError when initialized with an invalid endpoint" do
    lambda { Savon::Client.new "invalid" }.should raise_error ArgumentError
  end

  it "has a getter for accessing the Savon::WSDL" do
    @client.wsdl.should be_a Savon::WSDL
  end

  it "has a getter for accessing the Savon::Request" do
    @client.request.should be_a Savon::Request
  end

  it "has a getter for returning whether to use the Savon::WSDL (global setting)" do
    @client.wsdl?.should be_true

    Savon::Client.wsdl = false
    @client.wsdl?.should be_false
    Savon::Client.wsdl = true

    @client.wsdl = false
    @client.wsdl?.should be_false
  end

  it "responds to SOAP actions while still behaving as usual otherwise" do
    @client.respond_to?(UserFixture.soap_actions.first).should be_true
    @client.respond_to?(:object_id).should be_true
    @client.respond_to?(:some_undefined_method).should be_false
  end

  it "dispatches SOAP calls via method_missing and returns the Savon::Response" do
    @client.find_user.should be_a Savon::Response
  end

  it "raises a Savon::SOAPFault in case of a SOAP fault" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint(:soap_fault)
    lambda { client.find_user }.should raise_error Savon::SOAPFault
  end

  it "raises a Savon::HTTPError in case of an HTTP error" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint(:http_error)
    lambda { client.find_user }.should raise_error Savon::HTTPError
  end

  it "yields the SOAP object to a block when it expects one argument" do
    @client.find_user { |soap| soap.should be_a Savon::SOAP }
  end

  it "yields the SOAP and WSSE object to a block when it expects two argument" do
    @client.find_user do |soap, wsse|
      soap.should be_a Savon::SOAP
      wsse.should be_a Savon::WSSE
    end
  end

  it "still raises a NoMethodError for undefined methods" do
    lambda { @client.some_undefined_method }.should raise_error NoMethodError
  end

end
