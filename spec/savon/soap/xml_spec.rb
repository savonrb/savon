require "spec_helper"

describe Savon::SOAP::XML do
  before do
    @operation = WSDLFixture.authentication(:operations)[:authenticate]
    @action, @input = @operation[:action], @operation[:input]
    @soap = Savon::SOAP::XML.new @action, @input, Endpoint.soap
  end

  it "should default to SOAP 1.1" do
    Savon::SOAP::XML.version.should == 1
  end

  describe "xml returned via to_xml" do
    before do
      @xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>'
      @namespace = { "xmlns:ns" => "http://example.com" }
      @namespace_string = 'xmlns:ns="http://example.com"'
      @namespaces = { "xmlns:ns" => "http://ns.example.com", "xmlns:ns2" => "http://ns2.example.com" }

      # reset to defaults
      Savon::SOAP::XML.version = 1
      Savon::SOAP::XML.header = {}
      Savon::SOAP::XML.namespaces = {}
    end

    it "should contain an xml declaration" do
      @soap.to_xml.should include(@xml_declaration)
    end

    # namespaces

    it "should contain the namespace for SOAP 1.1" do
      @soap.to_xml.should include('xmlns:env="' + Savon::SOAP::Namespace[1] + '"')
    end

    it "should contain the namespace for SOAP 1.2 when defined globally" do
      Savon::SOAP::XML.version = 2
      @soap.to_xml.should include('xmlns:env="' + Savon::SOAP::Namespace[2] + '"')
    end

    it "should contain the namespace for SOAP 1.2 when defined per request" do
      @soap.version = 2
      @soap.to_xml.should include('xmlns:env="' + Savon::SOAP::Namespace[2] + '"')
    end

    it "should containg a xmlns:wsdl namespace defined via the :namespace shortcut method" do
      @soap.namespace = "http://wsdl.example.com"
      @soap.to_xml.should include('xmlns:wsdl="http://wsdl.example.com"')
    end

    it "should accept custom namespaces when defined globally" do
      Savon::SOAP::XML.namespaces = @namespace
      @soap.to_xml.should include("<env:Envelope " + @namespace_string)
    end

    it "should accept custom namespaces when defined per request" do
      @soap.namespaces = @namespace
      @soap.to_xml.should include("<env:Envelope " + @namespace_string)
    end

    it "should merge global and per request namespaces" do
      Savon::SOAP::XML.namespaces = @namespaces
      @soap.namespaces = @namespace
      @soap.to_xml.should include(
        'xmlns:ns="http://example.com"',
        'xmlns:ns2="http://ns2.example.com"'
      )
    end

    # header

    it "should not contain a header tag unless specified" do
      @soap.to_xml.should_not include("<env:Header>")
    end

    it "should accept a custom (String) header defined globally" do
      Savon::SOAP::XML.header = "<key>value</key>"
      @soap.to_xml.should include("<env:Header><key>value</key></env:Header>")
    end

    it "should accept a custom (Hash) header defined globally" do
      Savon::SOAP::XML.header[:key] = "value"
      @soap.to_xml.should include("<env:Header><key>value</key></env:Header>")
    end

    it "should accept a custom (String) header defined per request" do
      @soap.header = "<key>value</key>"
      @soap.to_xml.should include("<env:Header><key>value</key></env:Header>")
    end

    it "should accept a custom (Hash) header defined per request" do
      @soap.header[:key] = "value"
      @soap.to_xml.should include("<env:Header><key>value</key></env:Header>")
    end

    it "should merge global and per request headers defined as Strings" do
      Savon::SOAP::XML.header = "<key2>other value</key2>"
      @soap.header = "<key>value</key>"
      @soap.to_xml.should include(
        "<env:Header><key2>other value</key2><key>value</key></env:Header>"
      )
    end

    it "should merge global and per request headers defined as Hashes" do
      Savon::SOAP::XML.header = { :key => "value", :key2 => "global value" }
      @soap.header[:key2] = "request value"
      @soap.to_xml.should match(
        /<env:Header>(<key>value<\/key><key2>request value<\/key2>|<key2>request value<\/key2><key>value<\/key>)<\/env:Header>/
      )
    end

    it "should use the :header method from a given WSSE object to include a WSSE header" do
      wsse = "some compliant object"
      wsse.stubs(:header).returns("<wsse>authentication</wsse>")

      @soap.wsse = wsse
      @soap.to_xml.should include("<env:Header><wsse>authentication</wsse></env:Header>")
    end

    # input tag

    it "should contain a :wsdl namespaced input tag matching the :input property on instantiation" do
      @soap = Savon::SOAP::XML.new "someAction", "someInput", Endpoint.soap
      @soap.to_xml.should include('<wsdl:someInput>')
    end

    it "should fall back to using the :action property whem :input is blank" do
      @soap = Savon::SOAP::XML.new "someAction", "", Endpoint.soap
      @soap.to_xml.should include('<wsdl:someAction>')
    end

    it "should containg namespaces defined via an input tag Array containing the tag name and a Hash of namespaces" do
      input = ["someInput", { "otherNs" => "http://otherns.example.com" }]
      @soap = Savon::SOAP::XML.new "someAction", input, Endpoint.soap
      @soap.to_xml.should include('<wsdl:someInput otherNs="http://otherns.example.com">')
    end

    # xml body

    it "should contain the SOAP body defined as a Hash" do
      @soap.body = { :someTag => "some value" }
      @soap.to_xml.should include("<someTag>some value</someTag>")
    end

    it "should contain the SOAP body defined as an Object responding to :to_s" do
      @soap.body = "<someTag>some value</someTag>"
      @soap.to_xml.should include(@soap.body)
    end

    # xml

    it "should be a completely custom XML when specified" do
      @soap.xml = "custom SOAP body"
      @soap.to_xml.should == @soap.xml
    end

    # safety check

    it "should be a valid SOAP request" do
      @soap.to_xml.should include(
        @xml_declaration +
        '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' <<
          '<env:Body><wsdl:authenticate></wsdl:authenticate></env:Body>' <<
        '</env:Envelope>'
      )
    end
  end
end

