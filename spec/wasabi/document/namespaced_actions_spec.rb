require "spec_helper"

describe Wasabi::Document do
  context "with: namespaced_actions.wsdl" do

    subject(:document) { Wasabi::Document.new fixture(:namespaced_actions).read }

    its(:target_namespace) { should == "http://api.example.com/api/" }

    its(:endpoint) { should == URI("https://api.example.com/api/api.asmx") }

    it 'knows the operations' do
      expect(document).to have(3).operations

      pending
      #pp document.operations
      #operation = document.operations['Client.Delete']
      #expect(operation.input).to eq('GetUserLoginById')
      #expect(operation.soap_action).to eq('/api/api/GetUserLoginById')
      #expect(operation.nsid).to eq('typens')

      #operation = document.operations['GetAllContacts']
      #expect(operation.input).to eq('GetAllContacts')
      #expect(operation.soap_action).to eq('/api/api/GetAllContacts')
      #expect(operation.nsid).to eq('typens')

      #operation = document.operations['SearchUser']
      #expect(operation.input).to eq('SearchUser')
      #expect(operation.soap_action).to eq('/api/api/SearchUser')
      #expect(operation.nsid).to eq('typens')
    end

    #its(:operations) do
      #should include(
        #{ :delete_client => { :input => "Client.Delete", :action => "http://api.example.com/api/Client.Delete", :namespace_identifier => "tns" } },
        #{ :get_clients   => { :input => "User.GetClients", :action => "http://api.example.com/api/User.GetClients", :namespace_identifier => "tns" } },
        #{ :get_api_key   => { :input => "User.GetApiKey", :action => "http://api.example.com/api/User.GetApiKey", :namespace_identifier => "tns" } }
      #)
    #end

  end
end
