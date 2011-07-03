require "spec_helper"

describe Savon::Wasabi::Document do

  context "with a remote document" do
    before do
      response = HTTPI::Response.new 200, {}, Fixture.wsdl(:authentication)
      HTTPI.stubs(:get).returns(response)
    end

    it "should resolve via HTTP" do
      wsdl = Savon::Wasabi::Document.new("http://example.com?wsdl")
      wsdl.xml.should == Fixture.wsdl(:authentication)
    end

    it "should resolve via HTTPS" do
      wsdl = Savon::Wasabi::Document.new("https://example.com?wsdl")
      wsdl.xml.should == Fixture.wsdl(:authentication)
    end
  end

  context "with a local document" do
    before do
      HTTPI.expects(:get).never
    end

    it "should read the file" do
      wsdl = Savon::Wasabi::Document.new("spec/fixtures/wsdl/authentication.xml")
      wsdl.xml.should == Fixture.wsdl(:authentication)
    end
  end

  context "with raw XML" do
    before do
      HTTPI.expects(:get).never
      File.expects(:read).never
    end

    it "should use the raw XML" do
      wsdl = Savon::Wasabi::Document.new Fixture.wsdl(:authentication)
      wsdl.xml.should == Fixture.wsdl(:authentication)
    end
  end

end
