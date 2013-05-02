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
      subject.types["Save"].namespace.should == "http://example.com/actions"
    end

    it "records the fields under a type" do
      subject.types["Save"].children.should == [
        { :name => "article", :type => "article:Article", :qualified => true, :singular => true }
      ]
    end

    it "records multiple fields when there are more than one" do
      subject.types["Article"].children.should == [
        { :name => "Author", :type => "s:string", :qualified => true, :singular => true },
        { :name => "Title",  :type => "s:string", :qualified => true, :singular => true }
      ]
    end

    it "records the type of a field" do
      subject.types["Save"].children.first[:type].should == "article:Article"
      subject.namespaces["article"].should == "http://example.com/article"
    end

  end
end
