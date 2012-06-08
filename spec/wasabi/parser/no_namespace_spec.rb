require "spec_helper"

describe Wasabi::Parser do
  context "with: no_namespace.wsdl" do

    subject do
      parser = Wasabi::Parser.new Nokogiri::XML(xml)
      parser.parse
      parser
    end

    let(:xml) { fixture(:no_namespace).read }

    it "lists the types" do
      subject.types.keys.sort.should == ["McContact", "McContactArray", "MpUser", "MpUserArray"]
    end

    it "ignores xsd:all" do
      subject.types["MpUser"].keys.should == [:namespace]
    end

  end
end
