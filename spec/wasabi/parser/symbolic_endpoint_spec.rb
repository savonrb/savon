require "spec_helper"

describe Wasabi::Parser do
  context "with: symbolic_endpoint.wsdl" do

    subject(:parser) { Wasabi::Parser.new Nokogiri::XML(xml) }

    let(:xml) { fixture(:symbolic_endpoint).read }

    it "allows symbolic endpoints" do
      parser.endpoint.should be_nil
    end

  end
end
