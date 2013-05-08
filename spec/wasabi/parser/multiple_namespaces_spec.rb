require "spec_helper"

describe Wasabi::Parser do
  context "with: multiple_namespaces.wsdl" do

    subject(:parser) { Wasabi::Parser.new Nokogiri::XML(xml) }

    let(:xml) { fixture(:multiple_namespaces).read }

    it "lists the types" do
      parser.schemas.types.keys.sort.should == ["Article", "Save"]
    end

    it "records the namespace for each type" do
      pending "types currently don't know about their schema. this will have to be resolved " \
              "when we're creating instances of the schema"

      parser.schemas.types["Save"].namespace.should == "http://example.com/actions"
    end

    it "records the fields under a type" do
      parser.schemas.types["Save"].children.should == [
        { :name => "article", :type => "article:Article", :simple_type => false, :form => nil, :singular => true }
      ]
    end

    it "records multiple fields when there are more than one" do
      parser.schemas.types["Article"].children.should == [
        { :name => "Author", :type => "s:string", :simple_type => true, :form => nil, :singular => true },
        { :name => "Title",  :type => "s:string", :simple_type => true, :form => nil, :singular => true }
      ]
    end

    it "records the type of a field" do
      parser.schemas.types["Save"].children.first[:type].should == "article:Article"
      parser.namespaces["article"].should == "http://example.com/article"
    end

  end
end
