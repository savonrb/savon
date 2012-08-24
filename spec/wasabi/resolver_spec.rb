require "spec_helper"

describe Wasabi::Resolver do

  describe "#resolve" do
    it "resolves remote documents" do
      HTTPI.should_receive(:get) { HTTPI::Response.new(200, {}, "wsdl") }
      xml = Wasabi::Resolver.new("http://example.com?wsdl").resolve
      xml.should == "wsdl"
    end

    it "resolves local documents" do
      xml = Wasabi::Resolver.new(fixture(:authentication).path).resolve
      xml.should == fixture(:authentication).read
    end

    it "simply returns raw XML" do
      xml = Wasabi::Resolver.new("<xml/>").resolve
      xml.should == "<xml/>"
    end
  end

end
