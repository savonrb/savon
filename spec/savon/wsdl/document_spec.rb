require "spec_helper"

describe Savon::WSDL::Document do
  describe "a common WSDL document" do
    before { @wsdl = new_wsdl }

    it "is initialized with a Savon::Request object" do
      Savon::WSDL::Document.new HTTPI::Request.new(:url => Endpoint.wsdl)
    end

    it "it accepts a custom SOAP endpoint" do
      wsdl = Savon::WSDL::Document.new HTTPI::Request.new(:url => Endpoint.wsdl), "http://localhost"
      wsdl.soap_endpoint.should == "http://localhost"
    end

    it "is enabled by default" do
      @wsdl.enabled?.should be_true
    end

    it "has a getter for the namespace URI" do
      @wsdl.namespace_uri.should == WSDLFixture.authentication(:namespace_uri)
    end

    it "has a getter for returning an Array of available SOAP actions" do
      WSDLFixture.authentication(:operations).keys.each do |soap_action|
        @wsdl.soap_actions.should include(soap_action)
      end
    end

    it "has a getter for returning a Hash of available SOAP operations" do
      @wsdl.operations.should == WSDLFixture.authentication(:operations)
    end

    it "responds to SOAP actions while still behaving as usual otherwise" do
      WSDLFixture.authentication(:operations).keys.each do |soap_action|
        @wsdl.respond_to?(soap_action).should be_true
      end

      @wsdl.respond_to?(:object_id).should be_true
      @wsdl.respond_to?(:some_undefined_method).should be_false
    end

    it "returns the raw WSDL document for to_xml" do
      @wsdl.to_xml.should == WSDLFixture.authentication
    end
  end

  describe "a WSDL document having core sections without a namespace" do
    before { @wsdl = new_wsdl :no_namespace }

    it "returns the namespace URI" do
      @wsdl.namespace_uri.should == WSDLFixture.no_namespace(:namespace_uri)
    end

    it "returns an Array of available SOAP actions" do
      WSDLFixture.no_namespace(:operations).keys.each do |soap_action|
        @wsdl.soap_actions.should include(soap_action)
      end
    end

    it "returns a Hash of SOAP operations" do
      @wsdl.operations.should == WSDLFixture.no_namespace(:operations)
    end
  end

  describe "a WSDL document with namespaced SOAP actions" do
    before { @wsdl = new_wsdl :namespaced_actions }

    it "returns the namespace URI" do
      @wsdl.namespace_uri.should == WSDLFixture.namespaced_actions(:namespace_uri)
    end

    it "returns an Array of available SOAP actions" do
      WSDLFixture.namespaced_actions(:operations).keys.each do |soap_action|
        @wsdl.soap_actions.should include(soap_action)
      end
    end

    it "returns a Hash of SOAP operations" do
      @wsdl.operations.should == WSDLFixture.namespaced_actions(:operations)
    end
  end

  describe "a WSDL document from geotrust" do
    before { @wsdl = new_wsdl :geotrust }
    
    it "returns the namespace URI" do
      @wsdl.namespace_uri.should == WSDLFixture.geotrust(:namespace_uri)
    end
    
    it "returns an Array of available SOAP actions" do
      WSDLFixture.geotrust(:operations).keys.each do |soap_action|
        @wsdl.soap_actions.should include(soap_action)
      end
    end
    
    it "returns a Hash of SOAP operations" do
      @wsdl.operations.should == WSDLFixture.geotrust(:operations)
    end
  end

  def new_wsdl(fixture = nil)
    endpoint = fixture ? Endpoint.wsdl(fixture) : Endpoint.wsdl

    request = HTTPI::Request.new(:url => endpoint)
    HTTPI.stubs(:get).with(request).returns(HTTPI::Response.new 200, {}, WSDLFixture.load(fixture))
    Savon::WSDL::Document.new request
  end

end
