require "spec_helper"

describe Savon::WSDL::Document do

  shared_examples_for "a WSDL document" do
    it "should be present" do
      wsdl.should be_present
    end

    describe "#namespace" do
      it "should return the namespace URI" do
        wsdl.namespace.should == "http://v1_0.ws.auth.order.example.com/"
      end
    end

    describe "#soap_actions" do
      it "should return an Array of available SOAP actions" do
        wsdl.soap_actions.should == [:authenticate]
      end
    end

    describe "#soap_action" do
      it "should return the SOAP action for a given key" do
        wsdl.soap_action(:authenticate).should == "authenticate"
      end

      it "should return nil if no SOAP action could be found" do
        wsdl.soap_action(:unknown).should be_nil
      end
    end

    describe "#soap_input" do
      it "should return the SOAP input tag for a given key" do
        wsdl.soap_input(:authenticate).should == :authenticate
      end

      it "should return nil if no SOAP input tag could be found" do
        wsdl.soap_input(:unknown).should be_nil
      end
    end

    describe "#operations" do
      it "should return a Hash of SOAP operations" do
        wsdl.operations.should == {
          :authenticate => {
            :input => "authenticate", :action => "authenticate"
          }
        }
      end
    end

    describe "#document" do
      it "should return the raw WSDL document" do
        wsdl.document.should == Fixture.wsdl(:authentication)
      end

      it "should be memoized" do
        wsdl.document.should equal(wsdl.document)
      end
    end
  end

  context "with a remote document" do
    let(:wsdl) { Savon::WSDL::Document.new HTTPI::Request.new, Endpoint.wsdl }

    before do
      response = HTTPI::Response.new 200, {}, Fixture.wsdl(:authentication)
      HTTPI.stubs(:get).returns(response)
    end

    it_should_behave_like "a WSDL document"

    describe "#element_form_default" do
      it "should return :unqualified" do
        wsdl.element_form_default.should == :unqualified
      end
    end
  end

  context "with a local document" do
    let(:wsdl) do
      wsdl = "spec/fixtures/wsdl/authentication.xml"
      Savon::WSDL::Document.new HTTPI::Request.new, wsdl
    end

    before { HTTPI.expects(:get).never }

    it_should_behave_like "a WSDL document"
  end

  context "without a WSDL document" do
    let(:wsdl) { Savon::WSDL::Document.new HTTPI::Request.new }

    it "should not be present" do
      wsdl.should_not be_present
    end

    describe "#soap_action" do
      it "should return nil" do
        wsdl.soap_action(:authenticate).should be_nil
      end
    end

    describe "#soap_input" do
      it "should return nil" do
        wsdl.soap_input(:authenticate).should be_nil
      end
    end

    describe "#document" do
      it "should raise an ArgumentError" do
        lambda { wsdl.document }.should raise_error(ArgumentError)
      end
    end
  end

  context "with a WSDL document containing elementFormDefault='qualified'" do
    let(:wsdl) { Savon::WSDL::Document.new HTTPI::Request.new, Endpoint.wsdl }

    before do
      response = HTTPI::Response.new 200, {}, Fixture.wsdl(:geotrust)
      HTTPI.stubs(:get).returns(response)
    end

    describe "#element_form_default" do
      it "should return :qualified" do
        wsdl.element_form_default.should == :qualified
      end
    end
  end

  context "with a WSDL document specifying multiple namespaces" do
    let(:wsdl) { Savon::WSDL::Document.new HTTPI::Request.new, Endpoint.wsdl }

    before do
      response = HTTPI::Response.new 200, {}, Fixture.wsdl(:multiple_namespaces)
      HTTPI.stubs(:get).returns(response)
    end

    describe "#type_namespaces" do
      it "should return a list of namespaces defined in types section" do
        wsdl.type_namespaces.should =~ [
          [["Save"], "http://example.com/actions"],
          [["Save", "article"], "http://example.com/actions"],
          [["Article"], "http://example.com/article"],
          [["Article", "Author"], "http://example.com/article"],
          [["Article", "Title"], "http://example.com/article"]
        ]
      end
    end
    
    describe "#type_definitions" do
      it "should return the types of fields defined in this WSDL" do
        wsdl.type_definitions.should =~ [
          [["Save", "article"], "Article"]
        ]
      end
    end
  end

end
