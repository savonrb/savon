require "spec_helper"

describe Savon::SOAP do
  before { @soap = some_soap_instance }

  def some_soap_instance
    Savon::SOAP.new UserFixture.soap_actions[:find_user]
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

  describe "@version" do
    it "defaults to 1" do
      Savon::SOAP.version.should == 1
    end

    it "has accessor methods" do
      [2, 1].each do |soap_version|
        Savon::SOAP.version = soap_version
        Savon::SOAP.version.should == soap_version
      end
    end
  end

  describe "initialize" do
    it "expects a SOAP action map" do
      some_soap_instance
    end
  end

  describe "wsse" do
    it "expects a Savon::WSSE" do
      @soap.wsse = Savon::WSSE.new
    end
  end

  describe "action" do
    it "is an accessor for the SOAP action" do
      @soap.action.should == UserFixture.soap_actions[:find_user][:name]

      action = "someAction"
      @soap.action = action
      @soap.action.should == action
    end
  end

  describe "input" do
    it "sets the name of the SOAP input node" do
      @soap.input = "FindUserRequest"
    end
  end

  describe "header" do
    it "is an accessor for the SOAP header" do
      @soap.header.should be_a Hash
      @soap.header.should be_empty

      header = { "specialAuthKey" => "secret" }
      @soap.header = header
      @soap.header.should == header
    end
  end

  describe "body" do
    it "expects a SOAP-translatable Hash or an XML String" do
      @soap.body = { :id => 666 }
      @soap.body = "<id>666</id>"
    end
  end

  describe "namespaces" do
    it "defaults to a Hash with xmlns:env set to SOAP 1.1" do
      soap = some_soap_instance
      soap.namespaces.should == { "xmlns:env" => Savon::SOAP::SOAPNamespace[1] }
    end

    it "contains the xmlns:env for SOAP 1.2 if specified" do
      soap = some_soap_instance
      soap.version = 2
      soap.namespaces.should == { "xmlns:env" => Savon::SOAP::SOAPNamespace[2] }
    end
  end

  describe "version" do
    it "returns the SOAP version from options" do
      soap = some_soap_instance
      soap.version = 2
      soap.version.should == 2
    end

    it "returns the default SOAP version otherwise" do
      @soap.version.should == Savon::SOAP.version
    end
  end

  describe "to_xml" do
    before { Savon::SOAP.version = 1 }

    it "returns the XML for a SOAP request" do
      soap = some_soap_instance
      soap.namespaces["xmlns:wsdl"] = "http://v1_0.ws.user.example.com"
      soap.body = { :id => 666 }
      soap.to_xml.should == soap_body
    end

    it "caches the XML, returning the same Object every time" do
      @soap.to_xml.object_id.should == @soap.to_xml.object_id
    end

    it "uses the SOAP namespace for the SOAP version passed in via options" do
      soap = some_soap_instance
      soap.version = 2
      soap.to_xml.should include Savon::SOAP::SOAPNamespace[2]
    end

    it "uses the SOAP namespace for the default SOAP version otherwise" do
      Savon::SOAP.version = 2
      @soap.to_xml.should include Savon::SOAP::SOAPNamespace[2]
    end

    def soap_body
      "<env:Envelope xmlns:wsdl=\"http://v1_0.ws.user.example.com\" " <<
        "xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\">" <<
        "<env:Header></env:Header>" <<
        "<env:Body><wsdl:findUser><id>666</id></wsdl:findUser></env:Body>" <<
      "</env:Envelope>"
    end
  end

end
