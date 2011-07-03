require "spec_helper"

describe Wasabi::Document do
  context "with: geotrust.xml" do

    subject { Wasabi::Document.new fixture(:geotrust) }

    its(:namespace) { should == "http://api.geotrust.com/webtrust/query" }

    its(:endpoint) { should == URI("https://test-api.geotrust.com:443/webtrust/query.jws") }

    its(:element_form_default) { should == :qualified }

    it { should have(2).operations }

    its(:operations) do
      should include(
        { :get_quick_approver_list => { :input => "GetQuickApproverList", :action => "GetQuickApproverList" } },
        { :hello => { :input => "hello", :action => "hello" } }
      )
    end

  end
end
