require "spec_helper"

describe Savon::Response do
  before { @response = some_response_instance }

  def some_response_instance
    Savon::Response.new http_response_mock
  end

  def soap_fault_response_instance
    Savon::Response.new http_response_mock(200, UserFixture.soap_fault)
  end

  def http_error_response_instance
    Savon::Response.new http_response_mock(404, "", "Not found")
  end

  describe "@raise_errors" do
    it "defaults to true" do
      Savon::Response.raise_errors?.should be_true
    end

    it "has accessor methods" do
      Savon::Response.raise_errors = false
      Savon::Response.raise_errors?.should == false
      Savon::Response.raise_errors = true
    end
  end

  describe "initialize" do
    it "expects a Net::HTTPResponse" do
      some_response_instance
    end

    it "raises a Savon::SOAPFault in case of a SOAP fault" do
      lambda { soap_fault_response_instance }.should raise_error Savon::SOAPFault
    end
 
    it "does not raise a Savon::SOAPFault in case the default is turned off" do
      Savon::Response.raise_errors = false
      soap_fault_response_instance
      Savon::Response.raise_errors = true
    end
 
    it "raises a Savon::HTTPError in case of an HTTP error" do
      lambda { http_error_response_instance }.should raise_error Savon::HTTPError
    end

    it "does not raise a Savon::HTTPError in case the default is turned off" do
      Savon::Response.raise_errors = false
      http_error_response_instance
      Savon::Response.raise_errors = true
    end
  end

  describe "soap_fault?" do
    before { Savon::Response.raise_errors = false }

    it "does not return true in case the response seems to be ok" do
      @response.soap_fault?.should_not be_true
    end

    it "returns true in case of a SOAP fault" do
      response = soap_fault_response_instance
      response.soap_fault?.should be_true
    end

    after { Savon::Response.raise_errors = true }
  end

  describe "soap_fault" do
    before { Savon::Response.raise_errors = false }

    it "returns the SOAP fault message in case of a SOAP fault" do
      response = soap_fault_response_instance
      response.soap_fault.should == "(soap:Server) Fault occurred while processing."
    end

    after { Savon::Response.raise_errors = true }
  end

  describe "http_error?" do
    before { Savon::Response.raise_errors = false }

    it "does not return true in case the response seems to be ok" do
      @response.http_error?.should_not be_true
    end

    it "returns true in case of an HTTP error" do
      response = http_error_response_instance
      response.http_error?.should be_true
    end

    after { Savon::Response.raise_errors = true }
  end

  describe "http_error" do
    before { Savon::Response.raise_errors = false }

    it "returns the HTTP error message in case of an HTTP error" do
      response = http_error_response_instance
      response.http_error.should == "Not found (404)"
    end

    after { Savon::Response.raise_errors = true }
  end

  describe "to_hash" do
    it "returns the SOAP response body as a Hash" do
      @response.to_hash.should == UserFixture.response_hash
    end
  end

  describe "to_xml" do
    it "returns the SOAP response body" do
      @response.to_xml.should == UserFixture.user_response
    end
  end

  describe "to_s (alias)" do
    it "returns the SOAP response body" do
      @response.to_s.should == UserFixture.user_response
    end
  end

  def http_response_mock(code = 200, body = UserFixture.user_response, message = "OK")
    http_response_mock = mock "Net::HTTPResponse"
    http_response_mock.stubs :code => code.to_s, :message => message,
        :content_type => "text/html", :body => body
    http_response_mock
  end

end