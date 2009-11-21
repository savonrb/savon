require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Savon::Service do

  it 'bla' do
  end

=begin
  include SpecHelper

  # initialize
  describe "initialize" do
    it "raises an ArgumentError when called with an invalid endpoint" do
      ["", nil, "invalid", 123].each do |argument|
        lambda { Savon::Service.new(argument) }.should raise_error(ArgumentError)
      end
    end

    it "raises an ArgumentError when called with an invalid version" do
      ["", nil, "invalid", 123].each do |argument|
        lambda { Savon::Service.new("http://example.com", argument) }.
          should raise_error(ArgumentError)
      end
    end
  end

  # wsdl
  describe "wsdl" do
    before { @service = new_service_instance }

    it "returns an instance of Savon::WSDL" do
      @service.wsdl.should be_a(Savon::WSDL)
    end

    it "returns the exact same Savon::WSDL instance every time" do
      @service.wsdl.should equal(@service.wsdl)
    end
  end

  # method_missing
  describe "method_missing" do
    before { @service = new_service_instance }

    it "raises a NoMethodError when called with an invalid soap_action" do
      lambda { @service.invalid_action }.should raise_error(NoMethodError)
    end

    it "by default returns content from the response using the '//return' XPath" do
      @service.find_user.should == { :firstname => "The", :lastname => "Dude",
        :email => "thedude@example.com", :username => "thedude", :id => "123" }
    end

    it "returns the content of the response starting at a custom XPath" do
      @service.find_user(nil, "//email").should == "thedude@example.com"
    end

    it "returns nil if a given XPath does not match anything from the SOAP response" do
      @service.find_user(nil, "//doesNotMatchAnything").should be_nil
    end

    it "raises a Savon::SOAPFault in case of a SOAP fault" do
      @service = new_service_instance(:soap_fault => true)
      lambda { @service.find_user }.should raise_error(Savon::SOAPFault)
    end

    it "raises a Savon::HTTPError in case the server returned an error code and no SOAP fault" do
      @service = new_service_instance(:http_error => true)
      lambda { @service.find_user }.should raise_error(Savon::HTTPError)
    end

    it "raises a Savon::SOAPFault in case the server returned an error code and a SOAP fault" do
      @service = new_service_instance(:soap_fault => true, :http_error => true)
      lambda { @service.find_user }.should raise_error(Savon::SOAPFault)
    end

    it "returns the raw response body when :pure_response was set to +true+" do
      @service.pure_response = true
      @service.find_user.should == UserFixture.user_response
    end
  end
=end
end
