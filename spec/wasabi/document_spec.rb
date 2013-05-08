require "spec_helper"

describe Wasabi::Document do

  subject { Wasabi::Document.new fixture(:authentication).read }

  it "accepts a URL" do
    HTTPI.should_receive(:get) { HTTPI::Response.new(200, {}, "wsdl") }

    document = Wasabi::Document.new("http://example.com?wsdl")
    document.xml.should == "wsdl"
  end

  it "accepts a path" do
    document = Wasabi::Document.new fixture(:authentication).path
    document.xml.should == fixture(:authentication).read
  end

  it "accepts raw XML" do
    document = Wasabi::Document.new fixture(:authentication).read
    document.xml.should == fixture(:authentication).read
  end

end
