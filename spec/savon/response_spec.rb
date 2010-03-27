require "spec_helper"

describe Savon::Response do
  before { @response = Savon::Response.new http_response_mock }

  it "defaults to raises both Savon::SOAPFault and Savon::HTTPError" do
    Savon::Response.raise_errors?.should be_true
  end

  it "has both getter and setter for whether to raise errors (global setting)" do
    Savon::Response.raise_errors = false
    Savon::Response.raise_errors?.should == false
    Savon::Response.raise_errors = true
  end

  describe "initialize" do
    it "expects a Net::HTTPResponse" do
      Savon::Response.new http_response_mock
    end

    it "raises a Savon::SOAPFault in case of a SOAP fault" do
      lambda { savon_response_with :soap_fault }.should raise_error(Savon::SOAPFault)
    end

    it "does not raise a Savon::SOAPFault in case the default is turned off" do
      Savon::Response.raise_errors = false
      savon_response_with :soap_fault
      Savon::Response.raise_errors = true
    end

    it "raises a Savon::HTTPError in case of an HTTP error" do
      lambda { savon_response_with :http_error }.should raise_error(Savon::HTTPError)
    end

    it "does not raise a Savon::HTTPError in case the default is turned off" do
      Savon::Response.raise_errors = false
      savon_response_with :http_error
      Savon::Response.raise_errors = true
    end
  end

  describe "soap_fault?" do
    before { Savon::Response.raise_errors = false }

    it "does not return true in case the response seems to be ok" do
      @response.soap_fault?.should_not be_true
    end

    it "returns true in case of a SOAP fault" do
      savon_response_with(:soap_fault).soap_fault?.should be_true
    end

    after { Savon::Response.raise_errors = true }
  end

  describe "soap_fault" do
    before { Savon::Response.raise_errors = false }

    it "returns the SOAP fault message in case of a SOAP fault" do
      savon_response_with(:soap_fault).soap_fault.
        should == "(soap:Server) Fault occurred while processing."
    end

    it "returns the SOAP fault message in case of a SOAP 1.2 fault" do
      savon_response_with(:soap_fault12).soap_fault.
        should == "(soap:Sender) Sender Timeout"
    end

    after { Savon::Response.raise_errors = true }
  end

  describe "http_error?" do
    before { Savon::Response.raise_errors = false }

    it "does not return true in case the response seems to be ok" do
      @response.http_error?.should_not be_true
    end

    it "returns true in case of an HTTP error" do
      savon_response_with(:http_error).http_error?.should be_true
    end

    after { Savon::Response.raise_errors = true }
  end

  describe "http_error" do
    before { Savon::Response.raise_errors = false }

    it "returns the HTTP error message in case of an HTTP error" do
      savon_response_with(:http_error).http_error.should == "Not found (404)"
    end

    after { Savon::Response.raise_errors = true }
  end

  it "should return the SOAP response body as a Hash" do
    @response.to_hash[:authenticate_response][:return].should ==
      ResponseFixture.authentication(:to_hash)
  end

  it "should return a Hash for a SOAP multiRef response" do
    @response = Savon::Response.new http_response_mock(200, ResponseFixture.multi_ref, "OK")

    @response.to_hash[:list_response].should be_a(Hash)
    @response.to_hash[:multi_ref].should be_an(Array)
  end

  it "should return the raw SOAP response body" do
    @response.to_xml.should == ResponseFixture.authentication
    @response.to_s.should == ResponseFixture.authentication
  end

  it "should return the Net::HTTP response object" do
    @response.http.should be_a(Mocha::Mock)
    @response.http.should respond_to(:code)
    @response.http.should respond_to(:message)
    @response.http.should respond_to(:body)
  end

  describe "GZipped responses" do
    it "should be decoded if Content-encoding header is gzip" do
      @response = Savon::Response.new http_response_mock(200, body = "Encoded", "OK", 'content-encoding' => 'gzip')

      should_decode_body body

      @response.to_xml
    end

    # header logic extracted from http://dev.ctor.org/svn/soap4r/trunk/lib/soap/streamHandler.rb
    it "should be decoded if body starts with gzip header" do
      @response = Savon::Response.new http_response_mock(200, body = "\x1f\x8bEncoded", "OK")

      should_decode_body body

      @response.to_xml
    end

    it "should be decoded when header is set" do
      @response = Savon::Response.new http_response_mock(200, GzipResponseFixture.message, "OK", 'content-encoding' => 'gzip')
      @response.to_xml.should == "A short gzip encoded message\n"
    end

    it "should be decoded when header is not set" do
      @response = Savon::Response.new http_response_mock(200, GzipResponseFixture.message, "OK")
      @response.to_xml.should == "A short gzip encoded message\n"
    end
  end

  def should_decode_body(body)
    StringIO.expects(:new).with(body).returns(stream = mock("StringIO"))

    Zlib::GzipReader.expects(:new).with(stream).returns(mock("Zlib::GzipReader") do
      expects(:read)
      expects(:close)
    end)
  end

  def savon_response_with(error_type)
    mock = case error_type
      when :soap_fault   then http_response_mock 200, ResponseFixture.soap_fault
      when :soap_fault12 then http_response_mock 200, ResponseFixture.soap_fault12
      when :http_error   then http_response_mock 404, "", "Not found"
    end
    Savon::Response.new mock
  end

  def http_response_mock(code = 200, body = nil, message = "OK", headers = {})
    body ||= ResponseFixture.authentication
    mock = mock "Net::HTTPResponse"
    mock.stubs :code => code.to_s, :message => message, :content_type => "text/html", :body => body

    mock.stubs("[]").with(anything).returns(nil)
    headers.each { |key, value| mock.stubs("[]").with(key).returns(value) }

    mock
  end

end

