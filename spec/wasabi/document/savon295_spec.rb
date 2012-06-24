require "spec_helper"

describe Wasabi::Document do
  context "with: savon295.wsdl" do

    subject { Wasabi::Document.new fixture(:savon295).read }

    its(:operations) do
      should include(
        { :sendsms => { :input => "sendsms", :action => "sendsms", :namespace_identifier => "tns" } }
      )
    end

  end
end
