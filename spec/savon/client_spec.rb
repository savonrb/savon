require "spec_helper"

describe Savon::Client do
  before { @client = some_client_instance }

  def some_client_instance
    Savon::Client.new SpecHelper.some_endpoint
  end

  describe "initialize" do
    it "expects a SOAP endpoint String" do
      some_client_instance
    end

    it "raises an ArgumentError in case of an invalid endpoint" do
      lambda { Savon::Client.new "invalid" }.should raise_error ArgumentError
    end
  end

  describe "wsdl" do
    it "returns the Savon::WSDL" do
      @client.wsdl.should be_a Savon::WSDL
    end
  end

  describe "respond_to?" do
    it "returns true for available SOAP actions" do
      @client.respond_to?(UserFixture.soap_actions.keys.first).
        should be_true
    end

    it "still behaves like usual otherwise" do
      @client.respond_to?(:object_id).should be_true
      @client.respond_to?(:some_undefined_method).should be_false
    end
  end

  describe "method_missing" do
    it "dispatches SOAP requests for available SOAP actions" do
      @client.find_user.should be_a Savon::Response
    end

    it "raises a Savon::SOAPFault in case of a SOAP fault" do
      client = Savon::Client.new SpecHelper.soapfault_endpoint
      lambda { client.find_user }.should raise_error Savon::SOAPFault
    end

    it "raises a Savon::HTTPError in case of an HTTP error" do
      client = Savon::Client.new SpecHelper.httperror_endpoint
      lambda { client.find_user }.should raise_error Savon::HTTPError
    end

    it "yields the SOAP object to a block that expects one argument" do
      @client.find_user { |soap| soap.should be_a Savon::SOAP }
    end

    it "yields the SOAP and WSSE object to a block that expects two argument" do
      @client.find_user do |soap, wsse|
        soap.should be_a Savon::SOAP
        wsse.should be_a Savon::WSSE
      end
    end

    it "still raises a NoMethodError for undefined methods" do
      lambda { @client.some_undefined_method }.should raise_error NoMethodError
    end
  end

end