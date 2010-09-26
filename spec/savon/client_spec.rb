require "spec_helper"

describe Savon::Client do
  before do
    HTTPI.stubs(:get).returns(HTTPI::Response.new 200, {}, WSDLFixture.load)
    HTTPI.stubs(:post).returns(HTTPI::Response.new 200, {}, ResponseFixture.authentication)
    @client = Savon::Client.new :wsdl => Endpoint.wsdl
  end

  it "should use Savon::WSDL when a remote WSDL document was specified" do
    client = Savon::Client.new :wsdl => Endpoint.wsdl
    client.wsdl.should be_enabled
  end

  it "should not use Savon::WSDL when only a SOAP endpoint was specified" do
    client = Savon::Client.new :soap_endpoint => "http://localhost"
    client.wsdl.should_not be_enabled
  end

  it "should be able to use Savon::WSDL with a custom SOAP endpoint" do
    client = Savon::Client.new :wsdl => Endpoint.wsdl, :soap_endpoint => "http://localhost"
    client.wsdl.should be_enabled
    client.wsdl.soap_endpoint.should == "http://localhost"
  end

  it "should raise an ArgumentError when no WSDL or SOAP endpoint was specified" do
    lambda { Savon::Client.new }.should raise_error(ArgumentError)
  end

  it "should be able to send requests through a proxy server" do
    client = Savon::Client.new :wsdl => Endpoint.wsdl, :proxy => "http://proxy"
    client.request.proxy.should == URI("http://proxy")
  end

  it "should have a method that returns the Savon::WSDL::Document" do
    @client.wsdl.should be_a(Savon::WSDL::Document)
  end

  it "should have a method that returns the HTTPI::Request" do
    @client.request.should be_an(HTTPI::Request)
  end

  it "should respond to available SOAP actions while behaving as expected otherwise" do
    WSDLFixture.authentication(:operations).keys.each do |soap_action|
      @client.respond_to?(soap_action).should be_true
    end

    @client.respond_to?(:object_id).should be_true
    @client.respond_to?(:some_undefined_method).should be_false
  end

  it "should dispatch available SOAP calls via method_missing and return the Savon::SOAP::Response" do
    @client.authenticate.should be_a(Savon::SOAP::Response)
  end

  it "should raise a Savon::SOAPFault in case of a SOAP fault" do
    client = Savon::Client.new :soap_endpoint => Endpoint.soap(:soap_fault)
    HTTPI.stubs(:post).returns(HTTPI::Response.new 200, {}, ResponseFixture.soap_fault)
    lambda { client.authenticate }.should raise_error(Savon::SOAPFault)
  end

  it "should raise a Savon::HTTPError in case of an HTTP error" do
    client = Savon::Client.new :soap_endpoint => Endpoint.soap(:http_error)
    HTTPI.stubs(:post).returns(HTTPI::Response.new 500, {}, "")
    lambda { client.authenticate }.should raise_error(Savon::HTTPError)
  end

  it "should yield an instance of Savon::SOAP to a given block expecting one argument" do
    @client.authenticate { |soap| soap.should be_a(Savon::SOAP::XML) }
  end

  it "should yield an instance of Savon::SOAP::XML and Savon::WSSE to a gven block expecting two arguments" do
    @client.authenticate do |soap, wsse|
      soap.should be_a(Savon::SOAP::XML)
      wsse.should be_a(Savon::WSSE)
    end
  end

  it "should have a call method that forwards to method_missing for SOAP actions named after existing methods" do
    @client.call(:authenticate) { |soap| soap.should be_a(Savon::SOAP::XML) }
  end

  it "should raise a NoMethodError when the method does not match an available SOAP action or method" do
    lambda { @client.some_undefined_method }.should raise_error(NoMethodError)
  end

end
