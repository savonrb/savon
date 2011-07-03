require "spec_helper"

describe Wasabi::Document do
  context "with: two_bindings.xml" do

    subject { Wasabi::Document.new fixture(:two_bindings) }

    its(:element_form_default) { should == :unqualified }

    it { should have(3).operations }

    its(:operations) do
      should include(
        { :post => { :input => "Post", :action => "Post" } },
        { :post11only => { :input => "Post11only", :action => "Post11only" } },
        { :post12only => { :input => "Post12only", :action => "Post12only" } }
      )
    end

  end
end
