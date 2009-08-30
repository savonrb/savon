require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Savon::WSDL do
  include SpecHelper

  #namespace_uri
  describe "namespace_uri" do
    before { @wsdl = new_wsdl }

    it "returns the namespace URI from the WSDL" do
      @wsdl.namespace_uri == UserFixture.namespace_uri
    end

    it "returns the same object every time" do
      @wsdl.namespace_uri.should equal(@wsdl.namespace_uri)
    end
  end

  # soap_actions
  describe "soap_actions" do
    before { @wsdl = new_wsdl }

    it "returns the SOAP actions from the WSDL" do
      @wsdl.soap_actions == UserFixture.soap_actions
    end

    it "returns the same object every time" do
      @wsdl.soap_actions.should equal(@wsdl.soap_actions)
    end
  end

  # choice_elements
  describe "choice_elements" do
    before { @wsdl = new_wsdl }

    it "returns the choice elements from the WSDL" do
      @wsdl.choice_elements == UserFixture.choice_elements
    end

    it "returns the same object every time" do
      @wsdl.choice_elements.should equal(@wsdl.choice_elements)
    end
  end

  # initialize
  describe "initialize" do
    it "expects an endpoint URI and a Net::HTTP instance" do
      @wsdl = Savon::WSDL.new(some_uri, some_http)
    end
  end

  # to_s
  describe "to_s" do
    before { @wsdl = new_wsdl }

    it "returns nil before the WSDL document was retrieved" do
      @wsdl.to_s.should be_nil
    end

    it "returns the response body when available" do
      @wsdl.soap_actions # trigger http request
      @wsdl.to_s.should == UserFixture.user_wsdl
    end
  end
end
