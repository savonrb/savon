require "spec_helper"

describe Wasabi::Document do
  context "with: no_namespace.wsdl" do

    subject(:document) { Wasabi::Document.new fixture(:no_namespace).read }

    its(:namespace) { should == "urn:ActionWebService" }

    its(:endpoint) { should == URI("http://example.com/api/api") }

    it 'knows the operations' do
      expect(document).to have(3).operations

      operation = document.operations[:get_user_login_by_id]
      expect(operation.input).to eq('GetUserLoginById')
      expect(operation.soap_action).to eq('/api/api/GetUserLoginById')
      expect(operation.nsid).to eq('typens')

      operation = document.operations[:get_all_contacts]
      expect(operation.input).to eq('GetAllContacts')
      expect(operation.soap_action).to eq('/api/api/GetAllContacts')
      expect(operation.nsid).to eq('typens')

      operation = document.operations[:search_user]
      expect(operation.input).to eq('SearchUser')
      expect(operation.soap_action).to eq('/api/api/SearchUser')
      expect(operation.nsid).to eq('typens')
    end

  end
end
