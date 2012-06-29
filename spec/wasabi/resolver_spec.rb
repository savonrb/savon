require "spec_helper"

describe Wasabi::Resolver do

  describe "#xml" do
    it "resolves remote documents" do
      HTTPI.should_receive(:get) { HTTPI::Response.new(200, {}, "wsdl") }
      xml = Wasabi::Resolver.new("http://example.com?wsdl").xml
      xml.should == "wsdl"
    end

    it "resolves remote documents" do
      xml = Wasabi::Resolver.new(fixture(:authentication).path).xml
      xml.should == fixture(:authentication).read
    end

    it "simply returns raw XML" do
      xml = Wasabi::Resolver.new("<xml/>").xml
      xml.should == "<xml/>"
    end
  end

end
