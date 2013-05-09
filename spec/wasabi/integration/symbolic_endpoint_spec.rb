require "spec_helper"

describe Wasabi do
  context "with: symbolic_endpoint.wsdl" do

    subject(:wsdl) { Wasabi.new(xml) }

    let(:xml) { fixture(:symbolic_endpoint).read }

    it "allows symbolic endpoints" do
      wsdl.endpoint.should be_nil
    end

  end
end
