require "spec_helper"

describe Savon::SOAP::Response do

  describe ".new" do
    it "raises a Savon::SOAPFault in case of a SOAP fault" do
      lambda { new_response :body => ResponseFixture.soap_fault }.should raise_error(Savon::SOAPFault)
    end

    it "does not raise a Savon::SOAPFault in case the default is turned off" do
      Savon.raise_errors = false
      new_response :body => ResponseFixture.soap_fault
      Savon.raise_errors = true
    end

    it "raises a Savon::HTTPError in case of an HTTP error" do
      lambda { new_response :code => 500 }.should raise_error(Savon::HTTPError)
    end

    it "does not raise a Savon::HTTPError in case the default is turned off" do
      Savon.raise_errors = false
      new_response :code => 500
      Savon.raise_errors = true
    end
  end

  describe "#soap_fault?" do
    around do |example|
      Savon.raise_errors = false
      example.run
      Savon.raise_errors = true
    end

    it "does not return true in case the response seems to be ok" do
      new_response.soap_fault?.should be_false
    end

    it "returns true in case of a SOAP fault" do
      new_response(:body => ResponseFixture.soap_fault).soap_fault?.should be_true
    end
  end

  describe "#soap_fault" do
    around do |example|
      Savon.raise_errors = false
      example.run
      Savon.raise_errors = true
    end

    it "returns the SOAP fault message in case of a SOAP fault" do
      new_response(:body => ResponseFixture.soap_fault).soap_fault.should ==
        "(soap:Server) Fault occurred while processing."
    end

    it "returns the SOAP fault message in case of a SOAP 1.2 fault" do
      new_response(:body => ResponseFixture.soap_fault12).soap_fault.should ==
        "(soap:Sender) Sender Timeout"
    end
  end

  describe "#http_error?" do
    around do |example|
      Savon.raise_errors = false
      example.run
      Savon.raise_errors = true
    end

    it "does not return true in case the response seems to be ok" do
      new_response.http_error?.should_not be_true
    end

    it "returns true in case of an HTTP error" do
      new_response(:code => 500).http_error?.should be_true
    end
  end

  describe "#http_error" do
    around do |example|
      Savon.raise_errors = false
      example.run
      Savon.raise_errors = true
    end

    it "returns the HTTP error in case of an HTTP error" do
      new_response(:code => 404, :body => "").http_error.should == "HTTP error (404)"
    end

    it "returns the HTTP error and response body (if available) in case of an HTTP error" do
      new_response(:code => 404, :body => "Not found").http_error.should == "HTTP error (404): Not found"
    end
  end

  describe "#to_hash" do
    it "should return the SOAP response body as a Hash" do
      new_response.to_hash[:authenticate_response][:return].should ==
        ResponseFixture.authentication(:to_hash)
    end

    it "should return a Hash for a SOAP multiRef response" do
      response = new_response :body =>ResponseFixture.multi_ref
      
      response.to_hash[:list_response].should be_a(Hash)
      response.to_hash[:multi_ref].should be_an(Array)
    end
  end

  describe "#to_xml" do
    it "should return the raw SOAP response body" do
      new_response.to_xml.should == ResponseFixture.authentication
    end
  end

  describe "#http" do
    it "should return the Net::HTTP response object" do
      new_response.http.should be_an(HTTPI::Response)
    end
  end

  def new_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => ResponseFixture.authentication }
    response = defaults.merge options
    
    Savon::SOAP::Response.new HTTPI::Response.new(response[:code], response[:headers], response[:body])
  end

end
