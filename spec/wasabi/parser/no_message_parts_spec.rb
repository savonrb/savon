require "spec_helper"

describe Wasabi::Parser do
  context "with: no_message_parts.wsdl" do

    subject(:parser) { Wasabi::Parser.new Nokogiri::XML(xml) }

    let(:xml) { fixture(:no_message_parts).read }

    it "falls back to using the message type in the port element" do
      parser.operations[:save].input.should == "Save"
    end

    it "falls back to using the namespace ID in the port element" do
      parser.operations[:save].nsid.should == "actions"
    end
  end
end
