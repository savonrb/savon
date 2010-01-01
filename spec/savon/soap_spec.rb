require "spec_helper"

describe Savon::SOAP do
  before do
    @soap = Savon::SOAP.new
    @soap.action = WSDLFixture.authentication(:operations)[:authenticate][:action]
  end

  it "contains the SOAP namespace for each supported SOAP version" do
    Savon::SOAPVersions.each do |soap_version|
      Savon::SOAP::SOAPNamespace[soap_version].should be_a(String)
      Savon::SOAP::SOAPNamespace[soap_version].should_not be_empty
    end
  end

  it "contains the Content-Types for each supported SOAP version" do
    Savon::SOAPVersions.each do |soap_version|
      Savon::SOAP::ContentType[soap_version].should be_a(String)
      Savon::SOAP::ContentType[soap_version].should_not be_empty
    end
  end

  it "defaults to SOAP 1.1" do
    Savon::SOAP.version.should == 1
  end

  it "has both getter and setter for the SOAP version to use (global setting)" do
    [2, 1].each do |soap_version|
      Savon::SOAP.version = soap_version
      Savon::SOAP.version.should == soap_version
    end
  end

  it "has a setter for the Savon::WSSE" do
    @soap.wsse = Savon::WSSE.new
  end

  it "is has both getter and setter for the SOAP action" do
    @soap.action.should == WSDLFixture.authentication(:operations)[:authenticate][:action]

    @soap.action = "someAction"
    @soap.action.should == "someAction"
  end

  it "has a setter for the SOAP input" do
    @soap.input = "FindUserRequest"
  end

  it "has both getter and setter for the SOAP header" do
    @soap.header.should be_a(Hash)
    @soap.header.should be_empty

    @soap.header = { "specialAuthKey" => "secret" }
    @soap.header.should == { "specialAuthKey" => "secret" }
  end

  it "has a getter for the SOAP body, expecting a Hash or an XML String" do
    @soap.body = { :id => 666 }
    @soap.body = "<id>666</id>"
  end

  it "has a setter for specifying a Hash of namespaces" do
    namespaces = { "xmlns:env" => "http://example.com" }
    @soap.namespaces = namespaces
    @soap.namespaces.should == namespaces
  end

  describe "has a getter for namespaces" do
    it "which defaults to include the SOAP 1.1 namespace" do
      @soap.namespaces.should == { "xmlns:env" => Savon::SOAP::SOAPNamespace[1] }
    end

    it "which contains the SOAP 1.2 namespace if specified" do
      @soap.version = 2
      @soap.namespaces.should == { "xmlns:env" => Savon::SOAP::SOAPNamespace[2] }
    end
  end

  it "has both getter and setter for the SOAP endpoint" do
    @soap.endpoint.should be_nil

    soap_endpoint = URI EndpointHelper.soap_endpoint
    @soap.endpoint = soap_endpoint
    @soap.endpoint.should == soap_endpoint
  end

  it "has a getter for the SOAP version to use which defaults to SOAP 1.1" do
    @soap.version.should == Savon::SOAP.version
  end

  it "has a setter for specifying the SOAP version to use" do
    @soap.version = 2
    @soap.version.should == 2
  end

  describe "to_xml" do
    after { Savon::SOAP.version = 1 }

    it "returns the XML for a SOAP request" do
      @soap.namespaces["xmlns:wsdl"] = "http://v1_0.ws.auth.order.example.com/"
      @soap.body = { :id => 666 }

      @soap.to_xml.should include('xmlns:wsdl="http://v1_0.ws.auth.order.example.com/"')
      @soap.to_xml.should include('xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"')
      @soap.to_xml.should include('<wsdl:authenticate><id>666</id></wsdl:authenticate>')
    end

    it "caches the XML, returning the same Object every time" do
      @soap.to_xml.object_id.should == @soap.to_xml.object_id
    end

    it "uses the SOAP namespace for the specified SOAP version" do
      @soap.version = 2
      @soap.to_xml.should include(Savon::SOAP::SOAPNamespace[2])
    end

    it "uses the SOAP namespace for the default SOAP version otherwise" do
      Savon::SOAP.version = 2
      @soap.to_xml.should include(Savon::SOAP::SOAPNamespace[2])
    end
  end

end
