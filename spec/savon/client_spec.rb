require "spec_helper"

describe Savon::Client do
  before { @client = Savon::Client.new EndpointHelper.wsdl_endpoint }

  it "should be initialized with an endpoint String" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint
    client.request.http.proxy?.should be_false
  end

  it "should accept a proxy URI via an optional Hash of options" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint, :proxy => "http://proxy"
    client.request.http.proxy?.should be_true
    client.request.http.proxy_address == "http://proxy"
  end

  it "should accept a SOAP endpoint via an optional Hash of options" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint, :soap_endpoint => "http://localhost"
    client.wsdl.soap_endpoint.should == "http://localhost"
  end

  it "should have a method that returns the Savon::WSDL" do
    @client.wsdl.should be_a(Savon::WSDL)
  end

  it "should have a method that returns the Savon::Request" do
    @client.request.should be_a(Savon::Request)
  end

  it "should respond to available SOAP actions while behaving as expected otherwise" do
    WSDLFixture.authentication(:operations).keys.each do |soap_action|
      @client.respond_to?(soap_action).should be_true
    end

    @client.respond_to?(:object_id).should be_true
    @client.respond_to?(:some_undefined_method).should be_false
  end

  it "should dispatch available SOAP calls via method_missing and return the Savon::Response" do
    @client.authenticate.should be_a(Savon::Response)
  end

  it "should disable the Savon::WSDL when passed a method with an exclamation mark" do
    @client.wsdl.enabled?.should be_true
    [:operations, :namespace_uri, :soap_endpoint].each do |method|
      Savon::WSDL.any_instance.expects(method).never
    end

    response = @client.authenticate! do |soap|
      soap.input.should == "authenticate"
      soap.input.should == "authenticate"
    end
    response.should be_a(Savon::Response)
    @client.wsdl.enabled?.should be_false
  end

  it "should raise a Savon::SOAPFault in case of a SOAP fault" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint(:soap_fault)
    lambda { client.authenticate! }.should raise_error(Savon::SOAPFault)
  end

  it "should raise a Savon::HTTPError in case of an HTTP error" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint(:http_error)
    lambda { client.authenticate! }.should raise_error(Savon::HTTPError)
  end

  it "should yield an instance of Savon::SOAP to a given block expecting one argument" do
    @client.authenticate { |soap| soap.should be_a(Savon::SOAP) }
  end

  it "should yield an instance of Savon::SOAP and Savon::WSSE to a gven block expecting two arguments" do
    @client.authenticate do |soap, wsse|
      soap.should be_a(Savon::SOAP)
      wsse.should be_a(Savon::WSSE)
    end
  end

  it "should have a call method that forwards to method_missing for SOAP actions named after existing methods" do
    @client.call(:authenticate) { |soap| soap.should be_a(Savon::SOAP) }
  end

  it "should raise a NoMethodError when the method does not match an available SOAP action or method" do
    lambda { @client.some_undefined_method }.should raise_error(NoMethodError)
  end

end