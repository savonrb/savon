require "spec_helper"

describe Wasabi::Document do
  context "with: no_namespace.xml" do

    subject { Wasabi::Document.new fixture(:no_namespace) }

    its(:namespace) { should == "urn:ActionWebService" }

    its(:endpoint) { should == URI("http://example.com/api/api") }

    its(:element_form_default) { should == :unqualified }

    it { should have(3).operations }

    its(:operations) do
      should include(
        { :get_user_login_by_id => { :input => "GetUserLoginById", :action => "/api/api/GetUserLoginById" } },
        { :get_all_contacts => { :input => "GetAllContacts", :action => "/api/api/GetAllContacts" } },
        { :search_user => { :input => "SearchUser", :action => "/api/api/SearchUser" } }
      )
    end

  end
end
