require "spec_helper"

describe Wasabi::Document do
  context "with: multiple_namespaces.wsdl" do

    subject(:document) { Wasabi::Document.new fixture(:multiple_namespaces).read }

    its(:target_namespace) { should == "http://example.com/actions" }

    its(:endpoint) { should == URI("http://example.com:1234/soap") }

    it 'knows the operations' do
      expect(document).to have(1).operations

      operation = document.operations[:save]
      expect(operation.input).to eq('Save')
      expect(operation.soap_action).to eq('http://example.com/actions.Save')
      expect(operation.nsid).to eq('actions')
    end

    its(:type_namespaces) do
      pending "types currently don't know about their schema. this will have to be resolved " \
              "when we're creating instances of the schema"

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
