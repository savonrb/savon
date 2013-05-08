require "spec_helper"

describe Wasabi::Parser do
  context "with: no_namespace.wsdl" do

    subject(:parser) { Wasabi::Parser.new Nokogiri::XML(xml) }

    let(:xml) { fixture(:no_namespace).read }

    it "lists the elements" do
      parser.schemas.first.elements.keys.sort.should == []
    end

    it "lists the complexTypes" do
      parser.schemas.first.complex_types.keys.sort.should == ["McContact", "McContactArray", "MpUser", "MpUserArray"]
    end

  end
end
