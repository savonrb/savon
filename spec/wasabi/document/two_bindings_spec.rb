require "spec_helper"

describe Wasabi::Document do
  context "with: two_bindings.wsdl" do

    subject(:document) { Wasabi::Document.new fixture(:two_bindings).read }

    it 'knows the operations' do
      expect(document).to have(3).operations

      operation = document.operations[:post]
      expect(operation.input).to eq('Post')
      expect(operation.soap_action).to eq('Post')

      operation = document.operations[:post11only]
      expect(operation.input).to eq('Post11only')
      expect(operation.soap_action).to eq('Post11only')

      operation = document.operations[:post12only]
      expect(operation.input).to eq('Post12only')
      expect(operation.soap_action).to eq('Post12only')
    end

  end
end
