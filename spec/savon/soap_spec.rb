require "spec_helper"

describe Savon::SOAP do
  before do
    @operation = WSDLFixture.authentication(:operations)[:authenticate]
    @action, @input = @operation[:action], @operation[:input]
    @soap = Savon::SOAP.new @action, @input, EndpointHelper.soap_endpoint
  end

  it "should contain the SOAP namespace for each supported SOAP version" do
    Savon::SOAP::Versions.each do |soap_version|
      Savon::SOAP::Namespace[soap_version].should be_a(String)
      Savon::SOAP::Namespace[soap_version].should_not be_empty
    end
  end

  it "should contain the Content-Types for each supported SOAP version" do
    Savon::SOAP::Versions.each do |soap_version|
      Savon::SOAP::ContentType[soap_version].should be_a(String)
      Savon::SOAP::ContentType[soap_version].should_not be_empty
    end
  end

  it "should contain an Array of supported SOAP versions" do
    Savon::SOAP::Versions.should be_an(Array)
    Savon::SOAP::Versions.should_not be_empty
  end

  it "should contain the xs:dateTime format" do
    Savon::SOAP::DateTimeFormat.should be_a(String)
    Savon::SOAP::DateTimeFormat.should_not be_empty

    DateTime.new(2012, 03, 22, 16, 22, 33).strftime(Savon::SOAP::DateTimeFormat).
      should == "2012-03-22T16:22:33Z"
  end

  it "should contain a Regexp matching the xs:dateTime format" do
    Savon::SOAP::DateTimeRegexp.should be_a(Regexp)
    (Savon::SOAP::DateTimeRegexp === "2012-03-22T16:22:33").should be_true
  end

  it "should default to SOAP 1.1" do
    Savon::SOAP.version.should == 1
  end

  describe "xml returned via to_xml" do
    before do
      @xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>'
      @namespace = { "xmlns:ns" => "http://example.com" }
      @namespace_string = 'xmlns:ns="http://example.com"'
      @namespaces = { "xmlns:ns" => "http://ns.example.com", "xmlns:ns2" => "http://ns2.example.com" }

      # reset to defaults
      Savon::SOAP.version = 1
      Savon::SOAP.header = {}
      Savon::SOAP.namespaces = {}
    end

    it "should contain an xml declaration" do
      @soap.to_xml.should include(@xml_declaration)
    end

    # namespaces

    it "should contain the namespace for SOAP 1.1" do
      @soap.to_xml.should include('xmlns:env="' + Savon::SOAP::Namespace[1] + '"')
    end

    it "should contain the namespace for SOAP 1.2 when defined globally" do
      Savon::SOAP.version = 2
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
      Savon::SOAP.namespaces = @namespace
      @soap.to_xml.should include("<env:Envelope " + @namespace_string)
    end

    it "should accept custom namespaces when defined per request" do
      @soap.namespaces = @namespace
      @soap.to_xml.should include("<env:Envelope " + @namespace_string)
    end

    it "should merge global and per request namespaces" do
      Savon::SOAP.namespaces = @namespaces
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
      Savon::SOAP.header = "<key>value</key>"
      @soap.to_xml.should include("<env:Header><key>value</key></env:Header>")
    end

    it "should accept a custom (Hash) header defined globally" do
      Savon::SOAP.header[:key] = "value"
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
      Savon::SOAP.header = "<key2>other value</key2>"
      @soap.header = "<key>value</key>"
      @soap.to_xml.should include(
        "<env:Header><key2>other value</key2><key>value</key></env:Header>"
      )
    end

    it "should merge global and per request headers defined as Hashes" do
      Savon::SOAP.header = { :key => "value", :key2 => "global value" }
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
      @soap = Savon::SOAP.new "someAction", "someInput", EndpointHelper.soap_endpoint
      @soap.to_xml.should include('<wsdl:someInput>')
    end

    it "should fall back to using the :action property whem :input is blank" do
      @soap = Savon::SOAP.new "someAction", "", EndpointHelper.soap_endpoint
      @soap.to_xml.should include('<wsdl:someAction>')
    end

    it "should containg namespaces defined via an input tag Array containing the tag name and a Hash of namespaces" do
      input = ["someInput", { "otherNs" => "http://otherns.example.com" }]
      @soap = Savon::SOAP.new "someAction", input, EndpointHelper.soap_endpoint
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

