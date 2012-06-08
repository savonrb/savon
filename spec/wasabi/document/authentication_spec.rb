require "spec_helper"

describe Wasabi::Document do
  context "with: authentication.wsdl" do

    subject { Wasabi::Document.new fixture(:authentication).read }

    its(:namespace) { should == "http://v1_0.ws.auth.order.example.com/" }

    its(:endpoint) { should == URI("http://example.com/validation/1.0/AuthenticationService") }

    its(:element_form_default) { should == :unqualified }

    it { should have(1).operations }

    its(:operations) do
      should == {
        :authenticate => { :input => "authenticate", :action => "authenticate", :namespace_identifier => "tns" }
      }
    end

  end
end
