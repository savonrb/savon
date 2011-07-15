require "spec_helper"

describe Savon::SOAP::XML do
  let :xml do
    xml = Savon::SOAP::XML.new
    xml.endpoint = Endpoint.soap
    xml.input = :authenticate
    xml.body = { :id => 1 }
    xml
  end

  describe "#input" do
    it "sets the input tag" do
      xml.input = [:test, {}]
      xml.input.should == [:test, {}]
    end

    it "namespaces it if use_namespace was called" do
      xml.input = [:test, {}]
      xml.use_namespace(["test"], "http://example.com/test")
      xml.to_xml.should include('ins0="http://example.com/test"', '<ins0:test>')
    end

    it "uses the target namespace from the WSDL without an explicit namespace" do
      xml.input = [:namespace, :test, {}]
      xml.use_namespace(["test"], "http://example.com/test")

      xml.to_xml.should_not include('<namespace:test>')
      xml.to_xml.should include('ins0="http://example.com/test"', '<ins0:test>')
    end
  end

  describe "#endpoint" do
    it "sets the endpoint to use" do
      xml.endpoint = "http://test.com"
      xml.endpoint.should == "http://test.com"
    end
  end

  describe "#version" do
    it "defaults to SOAP 1.1" do
      xml.version.should == 1
    end

    it "defaults to the global default" do
      Savon.soap_version = 2
      xml.version.should == 2

      reset_soap_version
    end

    it "sets the SOAP version to use" do
      xml.version = 2
      xml.version.should == 2
    end

    it "raises in case of an invalid version" do
      lambda { xml.version = 3 }.should raise_error(ArgumentError)
    end
  end

  describe "#header" do
    it "defaults to an empty Hash" do
      xml.header.should == {}
    end

    it "sets the SOAP header" do
      xml.header = { "MySecret" => "abc" }
      xml.header.should == { "MySecret" => "abc" }
    end

    it "uses the global soap_header if set" do
      Savon.stubs(:soap_header).returns({ "MySecret" => "abc" })
      xml.header.should == { "MySecret" => "abc" }
    end
  end

  describe "#env_namespace" do
    it "defaults to :env" do
      xml.env_namespace.should == :env
    end

    it "sets the SOAP envelope namespace" do
      xml.env_namespace = :soapenv
      xml.env_namespace.should == :soapenv
    end

    it "uses the global env_namespace if set as the SOAP envelope namespace" do
      Savon.stubs(:env_namespace).returns(:soapenv)
      xml.env_namespace.should == :soapenv
    end
  end

  describe "#namespaces" do
    it "defaults to a Hash containing the namespace for SOAP 1.1" do
      xml.namespaces.should == { "xmlns:env" => "http://schemas.xmlsoap.org/soap/envelope/" }
    end

    it "defaults to a Hash containing the namespace for SOAP 1.2 if that's the current version" do
      xml.version = 2
      xml.namespaces.should == { "xmlns:env" => "http://www.w3.org/2003/05/soap-envelope" }
    end

    it "sets the SOAP header" do
      xml.namespaces = { "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema" }
      xml.namespaces.should == { "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema" }
    end
  end

  describe "#namespace_by_uri" do
    it "returns the identifier if found" do
      xml.namespace_by_uri("http://schemas.xmlsoap.org/soap/envelope/").
        should == "env"
    end

    it "returns nil if not found" do
      xml.namespace_by_uri("http://example.com/unregistered").
        should be_nil
    end
  end

  describe "#wsse" do
    it "sets the Savon::WSSE object" do
      xml.wsse = Savon::WSSE.new
      xml.wsse.should be_a(Savon::WSSE)
    end
  end

  describe "#body" do
    it "sets the SOAP body Hash" do
      xml.body = { :id => 1 }
      xml.to_xml.should include("<id>1</id>")
    end

    it "also accepts an XML String" do
      xml.body = "<id>1</id>"
      xml.to_xml.should include("<id>1</id>")
    end

    it "appends the namespaces to each element based on use_namespace" do
      xml.body = { :foo => { :bar => 5 }}
      xml.use_namespace(["authenticate", "foo"], "http://example.com/foo")
      xml.use_namespace(["authenticate", "foo", "bar"],
        "http://example.com/bar")

      xml.to_xml.should include(
        'xmlns:ins0="http://example.com/foo"',
        'xmlns:ins1="http://example.com/bar"',
        '<ins0:foo><ins1:bar>5</ins1:bar></ins0:foo>'
      )
    end

    it "does not add the same namespace uri twice" do
      xml.body = {}
      xml.use_namespace(["authenticate", "one"], "http://example.com/foo")
      xml.use_namespace(["authenticate", "two"], "http://example.com/foo")
      xml.to_xml.should include('xmlns:ins0="http://example.com/foo"')
      xml.to_xml.should_not include('xmlns:ins1')
    end

    it "can deal with two fields side by side" do
      xml.body = { :adam => { :cain => 5, :abel => 7 }}
      xml.use_namespace(["authenticate", "adam"], "http://example.com/parent")
      xml.use_namespace(["authenticate", "adam", "cain"], "http://example.com/child1")
      xml.use_namespace(["authenticate", "adam", "abel"], "http://example.com/child2")

      adam = Nokogiri::XML(xml.to_xml).at_xpath(".//ins0:adam")
      adam.should have(2).children
      adam.should have_children("ins1:cain" => 5, "ins2:abel" => 7)
    end

    it "does not add a namespace for things which don't match a use_namespace" do
      xml.body = {:food => {:fruit => "orange"}}
      xml.use_namespace(["authenticate", "foo"], "http://example.com/foo")
      xml.to_xml.should include("<food><fruit>orange</fruit></food>")
    end

    it "deals with types" do
      xml.body = {:food => {:fruit => "orange"}}
      xml.use_namespace(["authenticate", "food"],
        "http://example.com/auth")
      xml.use_namespace(["Food", "fruit"], "http://example.com/food")
      xml.define_type(["authenticate", "food"], "Food")

      xml.to_xml.should include(
        'xmlns:ins0="http://example.com/auth"',
        'xmlns:ins1="http://example.com/food"',
        '<ins0:food><ins1:fruit>orange</ins1:fruit></ins0:food>'
      )
    end
  end

  describe "#xml" do
    it "lets you specify a completely custom XML String" do
      xml.xml = "<custom>xml</custom>"
      xml.to_xml.should == "<custom>xml</custom>"
    end

    it "yields a Builder::XmlMarkup object to a given block" do
      xml.xml { |xml| xml.using("Builder") }
      xml.to_xml.should == '<?xml version="1.0" encoding="UTF-8"?><using>Builder</using>'
    end

    it "accepts options to pass to the Builder::XmlMarkup instruct!" do
      xml.xml :xml, :aaa => :bbb do |xml|
        xml.using("Builder")
      end

      xml.to_xml.should == '<?xml version="1.0" encoding="UTF-8" aaa="bbb"?><using>Builder</using>'
    end
  end

  describe "#to_xml" do
    after { reset_soap_version }

    context "by default" do
      it "starts with an XML declaration" do
        xml.to_xml.should match(/^<\?xml version="1.0" encoding="UTF-8"\?>/)
      end

      it "uses default SOAP envelope namespace" do
        xml.to_xml.should include("<env:Envelope", "<env:Body")
      end

      it "adds the xsd namespace" do
        uri = "http://www.w3.org/2001/XMLSchema"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:xsd="#{uri}"(.*)>/)
      end

      it "adds the xsi namespace" do
        uri = "http://www.w3.org/2001/XMLSchema-instance"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:xsi="#{uri}"(.*)>/)
      end

      it "has a SOAP envelope tag with a SOAP 1.1 namespace" do
        uri = "http://schemas.xmlsoap.org/soap/envelope/"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:env="#{uri}"(.*)>/)
      end

      it "has a SOAP body containing the SOAP input tag and body Hash" do
        xml.to_xml.should include('<env:Body><authenticate><id>1</id></authenticate></env:Body>')
      end

      it "accepts a SOAP body as an XML String" do
        xml.body = "<someId>1</someId>"
        xml.to_xml.should include('<env:Body><authenticate><someId>1</someId></authenticate></env:Body>')
      end

      it "does not contain a SOAP header" do
        xml.to_xml.should_not include('<env:Header')
      end
    end

    context "with a SOAP header" do
      it "contains the given header" do
        xml.header = {
          :token => "secret",
          :attributes! => { :token => { :xmlns => "http://example.com" } }
        }

        xml.to_xml.should include('<env:Header><token xmlns="http://example.com">secret</token></env:Header>')
      end
    end

    context "with the global SOAP version set to 1.2" do
      it "contains the namespace for SOAP 1.2" do
        Savon.soap_version = 2

        uri = "http://www.w3.org/2003/05/soap-envelope"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:env="#{uri}"(.*)>/)
        reset_soap_version
      end
    end

    context "with a global and request SOAP version" do
      it "contains the namespace for the request SOAP version" do
        Savon.soap_version = 2
        xml.version = 1

        uri = "http://schemas.xmlsoap.org/soap/envelope/"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:env="#{uri}"(.*)>/)
        reset_soap_version
      end
    end

    context "with the SOAP envelope namespace set to an empty String" do
      it "does not add a namespace to SOAP envelope tags" do
        xml.env_namespace = ""
        xml.to_xml.should include("<Envelope", "<Body")
      end
    end

    context "using the #namespace and #namespace_identifier" do
      it "contains the specified namespace" do
        xml.namespace_identifier = :wsdl
        xml.namespace = "http://example.com"
        xml.to_xml.should include('xmlns:wsdl="http://example.com"')
      end
    end

    context "with :element_form_default set to :qualified and a :namespace" do
      let :xml do
        xml = Savon::SOAP::XML.new
        xml.endpoint = Endpoint.soap
        xml.input = :authenticate
        xml.body = { :user => { :id => 1, ":noNamespace" => true } }
        xml
      end

      it "namespaces the default elements" do
        xml.element_form_default = :qualified
        xml.namespace_identifier = :wsdl

        xml.to_xml.should include(
          "<wsdl:user>",
          "<wsdl:id>1</wsdl:id>",
          "<noNamespace>true</noNamespace>"
        )
      end
    end

    context "with WSSE authentication" do
      it "contains a SOAP header with WSSE authentication details" do
        xml.wsse = Savon::WSSE.new
        xml.wsse.credentials "username", "password"

        xml.to_xml.should include(
          "<env:Header><wsse:Security",
          "<wsse:Username>username</wsse:Username>",
          "password</wsse:Password>"
        )
      end
    end

    context "with a simple input tag (Symbol)" do
      it "just adds the input tag" do
        xml.input = :simple
        xml.to_xml.should include('<simple><id>1</id></simple>')
      end
    end

    context "with a simple input tag (Array)" do
      it "just adds the input tag" do
        xml.input = [:simple]
        xml.to_xml.should include('<simple><id>1</id></simple>')
      end
    end

    context "with an input tag and a namespace Hash (Array)" do
      it "contains the input tag with namespaces" do
        xml.input = [:getUser, { "active" => true }]
        xml.to_xml.should include('<getUser active="true"><id>1</id></getUser>')
      end
    end

    context "with a prefixed input tag (Array)" do
      it "contains a prefixed input tag" do
        xml.input = [:wsdl, :getUser]
        xml.to_xml.should include('<wsdl:getUser><id>1</id></wsdl:getUser>')
      end
    end

    context "with a prefixed input tag and a namespace Hash (Array)" do
      it "contains a prefixed input tag with namespaces" do
        xml.input = [:wsdl, :getUser, { :only_active => false }]
        xml.to_xml.should include('<wsdl:getUser only_active="false"><id>1</id></wsdl:getUser>')
      end
    end
  end

  def reset_soap_version
    Savon.soap_version = Savon::SOAP::DefaultVersion
  end

end
