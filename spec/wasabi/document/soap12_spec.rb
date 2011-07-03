require "spec_helper"

describe Wasabi::Document do
  context "with: soap12.xml" do

    subject { Wasabi::Document.new fixture(:soap12) }

    its(:endpoint) { should == URI("http://blogsite.example.com/endpoint12") }

  end
end
