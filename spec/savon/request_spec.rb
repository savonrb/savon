require "spec_helper"

describe Savon::Request do
  before { @request = Savon::Request.new EndpointHelper.wsdl_endpoint }

  it "contains the ContentType for each supported SOAP version" do
    content_type = { 1 => "text/xml;charset=UTF-8", 2 => "application/soap+xml;charset=UTF-8" }
    content_type.each { |version, type| Savon::Request::ContentType[version].should == type }
  end

  # defaults to log request and response. disabled for spec execution

  it "has both getter and setter for whether to log (global setting)" do
    Savon::Request.log = true
    Savon::Request.log?.should be_true
    Savon::Request.log = false
    Savon::Request.log?.should be_false
  end

  it "defaults to use a Logger instance for logging" do
    Savon::Request.logger.should be_a(Logger)
  end

  it "has both getter and setter for the logger to use (global setting)" do
    Savon::Request.logger = {}
    Savon::Request.logger.should be_a(Hash)
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

  it "has a getter for the SOAP endpoint URI" do
    @request.endpoint.should == URI(EndpointHelper.wsdl_endpoint)
  end

  it "should have a getter for the proxy URI" do
    @request.proxy.should == URI("")
  end

  it "should have a getter for the HTTP headers which defaults to an empty Hash" do
    @request.headers.should == {}
  end

  it "should have a setter for the HTTP headers" do
    headers = { "some" => "thing" }

    @request.headers = headers
    @request.headers.should == headers
  end

  it "should return the Net::HTTP object" do
    @request.http.should be_kind_of(Net::HTTP)
  end

  it "should have a method for setting HTTP basic auth credentials" do
    @request.basic_auth "user", "password"
  end

  it "retrieves the WSDL document and returns the Net::HTTP response" do
    wsdl_response = @request.wsdl

    wsdl_response.should be_a(Net::HTTPResponse)
    wsdl_response.body.should == WSDLFixture.authentication
  end


  describe "when executing a SOAP request" do
    before :each do
      operation = WSDLFixture.authentication(:operations)[:authenticate]
      action, input = operation[:action], operation[:input]
      @soap = Savon::SOAP.new action, input, EndpointHelper.soap_endpoint
    end

    it "should return the Net::HTTP response" do
      soap_response = @request.soap @soap

      soap_response.should be_a(Net::HTTPResponse)
      soap_response.body.should == ResponseFixture.authentication
    end

    it "should include Accept-Encoding gzip if it is enabled" do
      @request = Savon::Request.new EndpointHelper.wsdl_endpoint, :gzip => true
      a_post = Net::HTTP::Post.new(@soap.endpoint.request_uri, {})

      Net::HTTP::Post.expects(:new).with(anything, has_entry("Accept-encoding" => "gzip,deflate")).returns(a_post)

      @request.soap @soap
    end

    it "should not include Accept-Encoding gzip if it is not enabled" do
      @request = Savon::Request.new EndpointHelper.wsdl_endpoint, :gzip => false
      a_post = Net::HTTP::Post.new(@soap.endpoint.request_uri, {})

      Net::HTTP::Post.expects(:new).with(anything, Not(has_entry("Accept-encoding" => "gzip,deflate"))).returns(a_post)

      @request.soap @soap
    end
  end

  it "should not include host when creating HTTP requests" do
    request = @request.send(:request, :wsdl)
    request.path.should_not include("example.com")
  end

end