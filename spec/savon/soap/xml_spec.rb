require "spec_helper"

describe Savon::SOAP::XML do
  let(:xml) { Savon::SOAP::XML.new Endpoint.soap, :authenticate, :id => 1 }

  describe ".to_hash" do
    it "should return a given SOAP response body as a Hash" do
      hash = Savon::SOAP::XML.to_hash Fixture.response(:authentication)
      hash[:authenticate_response][:return].should == {
        :success => true,
        :authentication_value => {
          :token_hash => "AAAJxA;cIedoT;mY10ExZwG6JuKgp2OYKxow==",
          :token => "a68d1d6379b62ff339a0e0c69ed4d9cf",
          :client => "radclient"
        }
      }
    end

    it "should return a Hash for a SOAP multiRef response" do
      hash = Savon::SOAP::XML.to_hash Fixture.response(:multi_ref)

      hash[:list_response].should be_a(Hash)
      hash[:multi_ref].should be_an(Array)
    end

    it "should add existing namespaced elements as an array" do
      hash = Savon::SOAP::XML.to_hash Fixture.response(:list)

      hash[:multi_namespaced_entry_response][:history].should be_a(Hash)
      hash[:multi_namespaced_entry_response][:history][:case].should be_an(Array)
    end
  end

  describe ".parse" do
    it "should convert the given XML into a Hash" do
      hash = Savon::SOAP::XML.parse Fixture.response(:list)
      hash["soapenv:Envelope"]["soapenv:Body"].should be_a(Hash)
    end
  end

  describe ".to_array" do
    let(:response_hash) { Fixture.response_hash :authentication }

    context "when the given path exists" do
      it "should return an Array containing the path value" do
        Savon::SOAP::XML.to_array(response_hash, :authenticate_response, :return).should ==
          [response_hash[:authenticate_response][:return]]
      end
    end

    context "when the given path returns nil" do
      it "should return an empty Array" do
        Savon::SOAP::XML.to_array(response_hash, :authenticate_response, :undefined).should == []
      end
    end

    context "when the given path does not exist at all" do
      it "should return an empty Array" do
        Savon::SOAP::XML.to_array(response_hash, :authenticate_response, :some, :wrong, :path).should == []
      end
    end
  end

  describe ".new" do
    it "should accept an endpoint, an input tag and a SOAP body" do
      xml = Savon::SOAP::XML.new Endpoint.soap, :authentication, :id => 1

      xml.endpoint.should == Endpoint.soap
      xml.input.should == :authentication
      xml.body.should == { :id => 1 }
    end
  end

  describe "#input" do
    it "should set the input tag" do
      xml.input = [:test, {}]
      xml.input.should == [:test, {}]
    end

    it "should namespace it if use_namespace was called" do
      xml.input = [:test, {}]
      xml.use_namespace(["test"], "http://example.com/test")
      xml.to_xml.should include('ins0="http://example.com/test"')
      xml.to_xml.should include('<ins0:test>')
    end

    it "should not namespace input if input was given an explicit namespace"
  end

  describe "#endpoint" do
    it "should set the endpoint to use" do
      xml.endpoint = "http://test.com"
      xml.endpoint.should == "http://test.com"
    end
  end

  describe "#version" do
    it "should default to SOAP 1.1" do
      xml.version.should == 1
    end

    it "should default to the global default" do
      Savon.soap_version = 2
      xml.version.should == 2

      reset_soap_version
    end

    it "should set the SOAP version to use" do
      xml.version = 2
      xml.version.should == 2
    end

    it "should raise an ArgumentError in case of an invalid version" do
      lambda { xml.version = 3 }.should raise_error(ArgumentError)
    end
  end

  describe "#header" do
    it "should default to an empty Hash" do
      xml.header.should == {}
    end

    it "should set the SOAP header" do
      xml.header = { "MySecret" => "abc" }
      xml.header.should == { "MySecret" => "abc" }
    end
  end

  describe "#env_namespace" do
    it "should default to :env" do
      xml.env_namespace.should == :env
    end

    it "should set the SOAP envelope namespace" do
      xml.env_namespace = :soapenv
      xml.env_namespace.should == :soapenv
    end
  end

  describe "#namespaces" do
    it "should default to a Hash containing the namespace for SOAP 1.1" do
      xml.namespaces.should == { "xmlns:env" => "http://schemas.xmlsoap.org/soap/envelope/" }
    end

    it "should default to a Hash containing the namespace for SOAP 1.2 if that's the current version" do
      xml.version = 2
      xml.namespaces.should == { "xmlns:env" => "http://www.w3.org/2003/05/soap-envelope" }
    end

    it "should set the SOAP header" do
      xml.namespaces = { "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema" }
      xml.namespaces.should == { "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema" }
    end
  end

  describe "#wsse" do
    it "should set the Savon::WSSE object" do
      xml.wsse = Savon::WSSE.new
      xml.wsse.should be_a(Savon::WSSE)
    end
  end

  describe "#body" do
    it "should set the SOAP body Hash" do
      xml.body = { :id => 1 }
      xml.to_xml.should include("<id>1</id>")
    end

    it "should also accepts an XML String" do
      xml.body = "<id>1</id>"
      xml.to_xml.should include("<id>1</id>")
    end

    it "appends namespaces to each element based on use_namespace" do
      xml.body = { :foo => { :bar => 5 }}
      xml.use_namespace(["authenticate", "foo"], "http://example.com/foo")
      xml.use_namespace(["authenticate", "foo", "bar"],
        "http://example.com/bar")
      xml.to_xml.should include('xmlns:ins0="http://example.com/foo"')
      xml.to_xml.should include('xmlns:ins1="http://example.com/bar"')
      xml.to_xml.should include(
        '<ins0:foo>' +
          '<ins1:bar>5</ins1:bar>' +
        '</ins0:foo>')
    end

    it "can deal with two fields side by side" do
      xml.body = { :adam => { :cain => 5, :abel => 7 }}
      xml.use_namespace(["authenticate", "adam"],
        "http://example.com/parent")
      xml.use_namespace(["authenticate", "adam", "cain"],
        "http://example.com/child1")
      xml.use_namespace(["authenticate", "adam", "abel"],
        "http://example.com/child2")
      xml.to_xml.should include('<ins0:adam><ins1:cain>5</ins1:cain><ins2:abel>7</ins2:abel></ins0:adam>')
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
      xml.to_xml.should include('xmlns:ins0="http://example.com/auth"')
      xml.to_xml.should include('xmlns:ins1="http://example.com/food"')
      xml.to_xml.should include('<ins0:food>' +
        '<ins1:fruit>orange</ins1:fruit>' +
      '</ins0:food>')
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
  end

  describe "#to_xml" do
    after { reset_soap_version }

    context "by default" do
      it "should start with an XML declaration" do
        xml.to_xml.should match(/^<\?xml version="1.0" encoding="UTF-8"\?>/)
      end

      it "should use default SOAP envelope namespace" do
        xml.to_xml.should include("<env:Envelope", "<env:Body")
      end

      it "should add the xsd namespace" do
        uri = "http://www.w3.org/2001/XMLSchema"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:xsd="#{uri}"(.*)>/)
      end

      it "should add the xsi namespace" do
        uri = "http://www.w3.org/2001/XMLSchema-instance"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:xsi="#{uri}"(.*)>/)
      end

      it "should have a SOAP envelope tag with a SOAP 1.1 namespace" do
        uri = "http://schemas.xmlsoap.org/soap/envelope/"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:env="#{uri}"(.*)>/)
      end

      it "should have a SOAP body containing the SOAP input tag and body Hash" do
        xml.to_xml.should include('<env:Body><authenticate><id>1</id></authenticate></env:Body>')
      end

      it "should accept a SOAP body as an XML String" do
        xml.body = "<someId>1</someId>"
        xml.to_xml.should include('<env:Body><authenticate><someId>1</someId></authenticate></env:Body>')
      end

      it "should not contain a SOAP header" do
        xml.to_xml.should_not include('<env:Header')
      end
    end

    context "with a SOAP header" do
      it "should contain the given header" do
        xml.header = {
          :token => "secret",
          :attributes! => { :token => { :xmlns => "http://example.com" } }
        }
        
        xml.to_xml.should include('<env:Header><token xmlns="http://example.com">secret</token></env:Header>')
      end
    end

    context "with the global SOAP version set to 1.2" do
      it "should contain the namespace for SOAP 1.2" do
        Savon.soap_version = 2

        uri = "http://www.w3.org/2003/05/soap-envelope"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:env="#{uri}"(.*)>/)
        reset_soap_version
      end
    end

    context "with a global and request SOAP version" do
      it "should contain the namespace for the request SOAP version" do
        Savon.soap_version = 2
        xml.version = 1

        uri = "http://schemas.xmlsoap.org/soap/envelope/"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:env="#{uri}"(.*)>/)
        reset_soap_version
      end
    end

    context "with the SOAP envelope namespace set to an empty String" do
      it "should not add a namespace to SOAP envelope tags" do
        xml.env_namespace = ""
        xml.to_xml.should include("<Envelope", "<Body")
      end
    end

    context "using the #namespace and #namespace_identifier" do
      it "should contain the specified namespace" do
        xml.namespace_identifier = :wsdl
        xml.namespace = "http://example.com"
        xml.to_xml.should include('xmlns:wsdl="http://example.com"')
      end
    end

    context "with :element_form_default set to :qualified and a :namespace" do
      let :xml do
        Savon::SOAP::XML.new Endpoint.soap, :authenticate, :user => { :id => 1, ":noNamespace" => true }
      end

      it "should namespace the default elements" do
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
      it "should containg a SOAP header with WSSE authentication details" do
        xml.wsse = Savon::WSSE.new
        xml.wsse.credentials "username", "password"

        xml.to_xml.should include("<env:Header><wsse:Security")
        xml.to_xml.should include("<wsse:Username>username</wsse:Username>")
        xml.to_xml.should include("password</wsse:Password>")
      end
    end

    context "with a simple input tag (Symbol)" do
      it "should just add the input tag" do
        xml.input = :simple
        xml.to_xml.should include('<simple><id>1</id></simple>')
      end
    end

    context "with a simple input tag (Array)" do
      it "should just add the input tag" do
        xml.input = :simple
        xml.to_xml.should include('<simple><id>1</id></simple>')
      end
    end

    context "with an input tag and a namespace Hash (Array)" do
      it "should contain the input tag with namespaces" do
        xml.input = [:getUser, { "active" => true }]
        xml.to_xml.should include('<getUser active="true"><id>1</id></getUser>')
      end
    end

    context "with a prefixed input tag (Array)" do
      it "should contain a prefixed input tag" do
        xml.input = [:wsdl, :getUser]
        xml.to_xml.should include('<wsdl:getUser><id>1</id></wsdl:getUser>')
      end
    end

    context "with a prefixed input tag and a namespace Hash (Array)" do
      it "should contain a prefixed input tag with namespaces" do
        xml.input = [:wsdl, :getUser, { :only_active => false }]
        xml.to_xml.should include('<wsdl:getUser only_active="false"><id>1</id></wsdl:getUser>')
      end
    end
  end

  def reset_soap_version
    Savon.soap_version = Savon::SOAP::DefaultVersion
  end

end
