require "spec_helper"

describe Savon::SOAP::XML do

  def xml(endpoint = nil, input = nil, body = nil)
    @xml ||= begin
      xml = Savon::SOAP::XML.new(config)
      xml.endpoint = endpoint || Endpoint.soap
      xml.input    = input    || [nil, :authenticate, {}]
      xml.body     = body     || { :id => 1 }
      xml
    end
  end

  let(:config) { Savon::Config.default }

  describe "#input" do
    it "should set the input tag" do
      xml.input = :test
      xml.input.should == :test
    end
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
      config.soap_version = 2
      xml.version.should == 2
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

    it "should use the global soap_header if set" do
      config.stubs(:soap_header).returns({ "MySecret" => "abc" })
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

    it "should use the global env_namespace if set as the SOAP envelope namespace" do
      config.stubs(:env_namespace).returns(:soapenv)
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
    it "should set the Akami::WSSE object" do
      xml.wsse = Akami.wsse
      xml.wsse.should be_a(Akami::WSSE)
    end
  end

  describe "#body" do
    it "should set the SOAP body Hash" do
      xml.body = { :id => 1 }
      xml.to_xml.should include("<id>1</id>")
    end

    it "should accepts an XML String" do
      xml.body = "<id>1</id>"
      xml.to_xml.should include("<id>1</id>")
    end

    it "should accept a block" do
      xml.body do |body|
        body.user { body.id 1 }
      end

      xml.to_xml.should include("<authenticate><user><id>1</id></user></authenticate>")
    end
  end

  describe "#encoding" do
    it "defaults to UTF-8" do
      xml.encoding.should == "UTF-8"
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

    it "allows to change the encoding" do
      xml.xml(:xml, :encoding => "US-ASCII") { |xml| xml.using("Builder") }
      xml.to_xml.should == '<?xml version="1.0" encoding="US-ASCII"?><using>Builder</using>'
    end
  end

  describe "#to_xml" do
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

    context "with a custom encoding" do
      after do
        xml.encoding = nil
      end

      it "should change the default encoding" do
        xml.encoding = "US-ASCII"
        xml.to_xml.should match(/^<\?xml version="1.0" encoding="US-ASCII"\?>/)
      end
    end

    context "with a SOAP header" do
      context "as a Hash" do
        it "should contain the given header" do
          xml.header = {
            :token => "secret",
            :attributes! => { :token => { :xmlns => "http://example.com" } }
          }

          xml.to_xml.should include('<env:Header><token xmlns="http://example.com">secret</token></env:Header>')
        end
      end

      context "as a String" do
        it "should contain the given header" do
          xml.header = %{<token xmlns="http://example.com">secret</token>}

          xml.to_xml.should include('<env:Header><token xmlns="http://example.com">secret</token></env:Header>')
        end
      end
    end

    context "with the global SOAP version set to 1.2" do
      it "should contain the namespace for SOAP 1.2" do
        config.soap_version = 2

        uri = "http://www.w3.org/2003/05/soap-envelope"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:env="#{uri}"(.*)>/)
      end
    end

    context "with a global and request SOAP version" do
      it "should contain the namespace for the request SOAP version" do
        config.soap_version = 2
        xml.version = 1

        uri = "http://schemas.xmlsoap.org/soap/envelope/"
        xml.to_xml.should match(/<env:Envelope (.*)xmlns:env="#{uri}"(.*)>/)
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
      it "should namespace the default elements" do
        xml = xml(Endpoint.soap, [nil, :authenticate, {}], :user => { :id => 1, ":noNamespace" => true })
        xml.element_form_default = :qualified
        xml.namespace_identifier = :wsdl

        xml.to_xml.should include("<wsdl:user>", "<wsdl:id>1</wsdl:id>", "<noNamespace>true</noNamespace>")
      end
    end

    context "with :element_form_default set to :unqualified and a :namespace" do
      it "should namespace the default elements" do
        xml = xml(Endpoint.soap, [nil, :authenticate, {}], :user => { :id => 1, ":noNamespace" => true })
        xml.element_form_default = :unqualified
        xml.namespace_identifier = :wsdl

        xml.to_xml.should include("<user>", "<id>1</id>", "<noNamespace>true</noNamespace>")
      end
    end

    context "with WSSE authentication" do
      it "should containg a SOAP header with WSSE authentication details" do
        xml.wsse = Akami.wsse
        xml.wsse.credentials "username", "password"

        xml.to_xml.should include("<env:Header><wsse:Security")
        xml.to_xml.should include("<wsse:Username>username</wsse:Username>")
        xml.to_xml.should include("password</wsse:Password>")
      end
    end

    context "with a simple input tag (Symbol)" do
      it "should just add the input tag" do
        xml.input = [nil, :simple, {}]
        xml.to_xml.should include('<simple><id>1</id></simple>')
      end
    end

    context "with a simple input tag (Array)" do
      it "should just add the input tag" do
        xml.input = [nil, :simple, {}]
        xml.to_xml.should include('<simple><id>1</id></simple>')
      end
    end

    context "with an input tag and a namespace Hash (Array)" do
      it "should contain the input tag with namespaces" do
        xml.input = [nil, :getUser, { "active" => true }]
        xml.to_xml.should include('<getUser active="true"><id>1</id></getUser>')
      end
    end

    context "with a prefixed input tag (Array)" do
      it "should contain a prefixed input tag" do
        xml.input = [:wsdl, :getUser, {}]
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

  describe "#add_namespaces_to_body" do
    before :each do
      xml.used_namespaces.merge!({
        ["authenticate", "id"] =>"ns0",
        ["authenticate", "name"] =>"ns1",
        ["authenticate", "name", "firstName"] =>"ns2"
      })
    end

    it "adds namespaces" do
      body = {:id => 1, :name => {:first_name => 'Bob'}}
      xml.send(:add_namespaces_to_body, body).should == {"ns0:id" => "1", "ns1:name" => {"ns2:firstName" => "Bob"}}
    end

    it "adds namespaces to order! list" do
      body = {:id => 1, :name => {:first_name => 'Bob', :order! => [:first_name]}, :order! => [:id, :name]}
      xml.send(:add_namespaces_to_body, body).should == {
        "ns0:id" => "1",
        "ns1:name" => {
          "ns2:firstName" => "Bob",
          :order! => ["ns2:firstName"]
        },
        :order! => ["ns0:id", "ns1:name"]
      }
    end
  end

end

