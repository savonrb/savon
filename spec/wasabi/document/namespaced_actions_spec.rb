require "spec_helper"

describe Wasabi::Document do
  context "with: namespaced_actions.wsdl" do

    subject { Wasabi::Document.new fixture(:namespaced_actions).read }

    its(:namespace) { should == "http://api.example.com/api/" }

    its(:endpoint) { should == URI("https://api.example.com/api/api.asmx") }

    its(:element_form_default) { should == :qualified }

    it { should have(3).operations }

    its(:operations) do
      should include(
        { :delete_client => { :input => "Client.Delete", :action => "http://api.example.com/api/Client.Delete", :namespace_identifier => "tns" } },
        { :get_clients   => { :input => "User.GetClients", :action => "http://api.example.com/api/User.GetClients", :namespace_identifier => "tns" } },
        { :get_api_key   => { :input => "User.GetApiKey", :action => "http://api.example.com/api/User.GetApiKey", :namespace_identifier => "tns" } }
      )
    end

  end
end
