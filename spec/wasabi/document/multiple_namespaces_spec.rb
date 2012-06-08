require "spec_helper"

describe Wasabi::Document do
  context "with: multiple_namespaces.wsdl" do

    subject { Wasabi::Document.new fixture(:multiple_namespaces).read }

    its(:namespace) { should == "http://example.com/actions" }

    its(:endpoint) { should == URI("http://example.com:1234/soap") }

    its(:element_form_default) { should == :qualified }

    it { should have(1).operations }

    its(:operations) do
      should == { :save => { :input => "Save", :action => "http://example.com/actions.Save", :namespace_identifier => "actions" } }
    end

    its(:type_namespaces) do
      should =~ [
        [["Save"], "http://example.com/actions"],
        [["Save", "article"], "http://example.com/actions"],
        [["Article"], "http://example.com/article"],
        [["Article", "Author"], "http://example.com/article"],
        [["Article", "Title"], "http://example.com/article"]
      ]
    end

    its(:type_definitions) do
      should =~ [ [["Save", "article"], "Article"] ]
    end

  end
end
