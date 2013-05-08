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
      subject.schemas.types.keys.sort.should == ["Article", "Save"]
    end

    it "records the namespace for each type" do
      pending "types currently don't know about their schema. this will have to be resolved " \
              "when we're creating instances of the schema"

      subject.schemas.types["Save"].namespace.should == "http://example.com/actions"
    end

    it "records the fields under a type" do
      subject.schemas.types["Save"].children.should == [
        { :name => "article", :type => "article:Article", :simple_type => false, :form => nil, :singular => true }
      ]
    end

    it "records multiple fields when there are more than one" do
      subject.schemas.types["Article"].children.should == [
        { :name => "Author", :type => "s:string", :simple_type => true, :form => nil, :singular => true },
        { :name => "Title",  :type => "s:string", :simple_type => true, :form => nil, :singular => true }
      ]
    end

    it "records the type of a field" do
      subject.schemas.types["Save"].children.first[:type].should == "article:Article"
      subject.namespaces["article"].should == "http://example.com/article"
    end

  end
end
