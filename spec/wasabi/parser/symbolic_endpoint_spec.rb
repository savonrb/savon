require "spec_helper"

describe Wasabi::Parser do
  context "with: symbolic_endpoint.xml" do

    subject do
      parser = Wasabi::Parser.new Nokogiri::XML(xml)
      parser.parse
      parser
    end

    let(:xml) { fixture(:symbolic_endpoint) }

    it "allows symbolic endpoints" do
      subject.endpoint.should be_nil
    end

  end
end
