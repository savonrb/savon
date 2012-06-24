require "spec_helper"

describe Wasabi::Parser do
  context "with: no_message_parts.wsdl" do

    subject do
      parser = Wasabi::Parser.new Nokogiri::XML(xml)
      parser.parse
      parser
    end

    let(:xml) { fixture(:no_message_parts).read }

    it "falls back to using the message type in the port element" do
      subject.operations[:save][:input].should == "Save"
    end

    it "falls back to using the namespace ID in the port element" do
      subject.operations[:save][:namespace_identifier].should == "actions"
    end
  end
end
