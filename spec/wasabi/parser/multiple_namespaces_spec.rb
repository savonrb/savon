require "spec_helper"

describe Wasabi::Parser do
  context "with: multiple_namespaces.wsdl" do

    subject do
      parser = Wasabi::Parser.new Nokogiri::XML(xml)
      parser.parse
      parser
    end

    let(:xml) { fixture(:multiple_namespaces).read }

    it "lists the types" do
      subject.types.keys.sort.should == ["Article", "Save"]
    end

    it "records the namespace for each type" do
      subject.types["Save"][:namespace].should == "http://example.com/actions"
    end

    it "records the fields under a type" do
      subject.types["Save"].keys.should =~ ["article", :namespace]
    end

    it "records multiple fields when there are more than one" do
      subject.types["Article"].keys.should =~ ["Title", "Author", :namespace]
    end

    it "records the type of a field" do
      subject.types["Save"]["article"][:type].should == "article:Article"
      subject.namespaces["article"].should == "http://example.com/article"
    end

  end
end
