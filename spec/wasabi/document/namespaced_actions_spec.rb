require "spec_helper"

describe Wasabi::Document do
  context "with: namespaced_actions.xml" do

    subject { Wasabi::Document.new fixture(:namespaced_actions) }

    its(:namespace) { should == "http://api.example.com/api/" }

    its(:endpoint) { should == URI("https://api.example.com/api/api.asmx") }

    its(:element_form_default) { should == :qualified }

    it { should have(3).operations }

    its(:operations) do
      should include(
        { :delete_client => { :input => "DeleteClient", :action => "http://api.example.com/api/Client.Delete" } },
        { :get_clients   => { :input => "GetClients", :action => "http://api.example.com/api/User.GetClients" } },
        { :get_api_key   => { :input => "GetApiKey", :action => "http://api.example.com/api/User.GetApiKey" } }
      )
    end

  end
end
