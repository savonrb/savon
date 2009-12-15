require "spec_helper"

describe Savon::Request do
  before { @request = Savon::Request.new EndpointHelper.wsdl_endpoint }

  it "contains the ContentType for each supported SOAP version" do
    Savon::SOAPVersions.each do |soap_version|
      Savon::Request::ContentType[soap_version].should be_a String
      Savon::Request::ContentType[soap_version].should_not be_empty
    end
  end

  # defaults to log request and response. disabled for spec execution

  it "has both getter and setter for whether to log (global setting)" do
    Savon::Request.log = true
    Savon::Request.log?.should be_true
    Savon::Request.log = false
    Savon::Request.log?.should be_false
  end

  it "defaults to use a Logger instance for logging" do
    Savon::Request.logger.should be_a Logger
  end

  it "has both getter and setter for the logger to use (global setting)" do
    Savon::Request.logger = nil
    Savon::Request.logger.should be_nil
    Savon::Request.logger = Logger.new STDOUT
  end

  it "defaults to :debug for logging" do
    Savon::Request.log_level.should == :debug
  end

  it "has both getter and setter for the log level to use (global setting)" do
    Savon::Request.log_level = :info
    Savon::Request.log_level.should == :info
    Savon::Request.log_level = :debug
  end

  it "is initialized with a SOAP endpoint String" do
    Savon::Request.new EndpointHelper.wsdl_endpoint
  end

  it "raises an ArgumentError when initialized with an invalid endpoint" do
    lambda { Savon::Request.new "invalid" }.should raise_error ArgumentError
  end

  it "should be optionally initialized with a proxy string" do
    Savon::Request.new EndpointHelper.wsdl_endpoint, 'http://localhost:8080'
  end

  it "raises an ArgumentError when initialized with an invalid proxy" do
    lambda { Savon::Request.new EndpointHelper.wsdl_endpoint, "invalid" }.should raise_error ArgumentError
  end

  it "has a getter for the SOAP endpoint URI" do
    @request.endpoint.should == URI(EndpointHelper.wsdl_endpoint)
  end

  it "should have a getter for the Proxy URI" do
    @request.proxy.should == URI('')
  end

  it "has a setter for specifying an open_timeout" do
    @request.open_timeout = 30
  end

  it "has a setter for specifying a read_timeout" do
    @request.read_timeout = 30
  end

  it "retrieves the WSDL document and returns the Net::HTTPResponse" do
    wsdl_response = @request.wsdl

    wsdl_response.should be_a Net::HTTPResponse
    wsdl_response.body.should == UserFixture.user_wsdl
  end

  it "executes a SOAP request and returns the Net::HTTPResponse" do
    soap_response = @request.soap Savon::SOAP.new

    soap_response.should be_a Net::HTTPResponse
    soap_response.body.should == UserFixture.user_response
  end

end
