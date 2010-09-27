require "spec_helper"

describe Savon::WSDL::Document do

  context "with a remote document" do
    let(:wsdl) { Savon::WSDL::Document.new HTTPI::Request.new, Endpoint.wsdl }
    before { HTTPI.stubs(:get).returns(new_response) }

    it "should be present" do
      wsdl.should be_present
    end

    describe "#namespace" do
      it "should return the namespace URI" do
        wsdl.namespace.should == WSDLFixture.authentication(:namespace)
      end
    end

    describe "#soap_actions" do
      it "should return an Array of available SOAP actions" do
        wsdl.soap_actions.should include(*WSDLFixture.authentication(:operations).keys)
      end
    end
  end

  context "with a local document" do
    let(:wsdl) do
      wsdl = "spec/fixtures/wsdl/xml/authentication.xml"
      Savon::WSDL::Document.new HTTPI::Request.new, wsdl
    end

    before { HTTPI.expects(:get).never }

    it "should be present" do
      wsdl.should be_present
    end

    describe "#namespace" do
      it "should return the namespace URI" do
        wsdl.namespace.should == WSDLFixture.authentication(:namespace)
      end
    end

    describe "#soap_actions" do
      it "should return an Array of available SOAP actions" do
        wsdl.soap_actions.should include(*WSDLFixture.authentication(:operations).keys)
      end
    end
  end

  def new_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => WSDLFixture.load }
    response = defaults.merge options
    
    HTTPI::Response.new(response[:code], response[:headers], response[:body])
  end

end
__END__

    it "has a getter for the namespace URI" do
      @wsdl.namespace.should == WSDLFixture.authentication(:namespace_uri)
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


end
