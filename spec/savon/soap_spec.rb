require "spec_helper"

describe Savon::SOAP do
  before { @soap = new_soap_instance }

  describe "@version" do
    it "defaults to 1" do
      Savon::SOAP.version.should == 1
    end

    it "has accessor methods" do
      [1, 2].each do |soap_version|
        Savon::SOAP.version = soap_version
        Savon::SOAP.version.should == soap_version
      end
    end
  end

  describe "initialize" do
    it "expects the SOAP action, body, options and the namespace URI" do
      new_soap_instance
    end
  end

  describe "action" do
    it "returns the SOAP action" do
      @soap.action.should == UserFixture.soap_actions[:find_user]
    end
  end

  describe "options" do
    it "returns the SOAP options" do
      @soap.options.should == {}
    end
  end

  describe "body" do
    before { Savon::SOAP.version = 1 }

    it "returns the XML for a SOAP request" do
      @soap.body.should == soap_body
    end

    it "caches the XML, returning the same Object every time" do
      @soap.body.object_id.should == @soap.body.object_id
    end

    it "uses the SOAP namespace for the SOAP version passed in via options" do
      soap = new_soap_instance :soap_version => 2
      soap.body.should include Savon::SOAP::SOAPNamespace[2]
    end

    it "uses the SOAP namespace for the default SOAP version otherwise" do
      Savon::SOAP.version = 2
      @soap.body.should include Savon::SOAP::SOAPNamespace[2]
    end

    def soap_body
      "<env:Envelope xmlns:wsdl=\"http://v1_0.ws.user.example.com\" " <<
        "xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\">" <<
        "<env:Header></env:Header>" <<
        "<env:Body><wsdl:findUser><id>666</id></wsdl:findUser></env:Body>" <<
      "</env:Envelope>"
    end
  end

  describe "version" do
    it "returns the SOAP version from options" do
      soap = new_soap_instance :soap_version => 2
      soap.version.should == 2
    end

    it "returns the default SOAP version otherwise" do
      @soap.version.should == Savon::SOAP.version
    end
  end

  def new_soap_instance(options = {})
    Savon::SOAP.new UserFixture.soap_actions[:find_user], { :id => 666 },
      options, UserFixture.namespace_uri
  end

  describe "SOAPNamespace" do
    it "contains the SOAP namespace for each supported SOAP version" do
      Savon::SOAPVersions.each do |soap_version|
        Savon::SOAP::SOAPNamespace[soap_version].should be_a String
        Savon::SOAP::SOAPNamespace[soap_version].should_not be_empty
      end
    end
  end

  describe "ContentType" do
    it "contains the Content-Types for each supported SOAP version" do
      Savon::SOAPVersions.each do |soap_version|
        Savon::SOAP::ContentType[soap_version].should be_a String
        Savon::SOAP::ContentType[soap_version].should_not be_empty
      end
    end
  end

end
