require "spec_helper"

describe Wasabi::Document do
  context "with: geotrust.wsdl" do

    subject(:document) { Wasabi::Document.new fixture(:geotrust).read }

    its(:target_namespace) { should == "http://api.geotrust.com/webtrust/query" }

    its(:endpoint) { should == URI("https://test-api.geotrust.com:443/webtrust/query.jws") }

    it 'knows the operations' do
      expect(document).to have(2).operations

      operation = document.operations[:get_quick_approver_list]
      expect(operation.input).to eq('GetQuickApproverList')
      expect(operation.soap_action).to eq('GetQuickApproverList')

      operation = document.operations[:hello]
      expect(operation.input).to eq('hello')
      expect(operation.soap_action).to eq('hello')
    end

  end
end
