require "spec_helper"

describe Wasabi::Parser do
  context "with: import_port_types.wsdl" do

    subject do
      parser = Wasabi::Parser.new Nokogiri::XML(xml)
      parser.parse
      parser
    end

    let(:xml) { fixture(:import_port_types).read }

    it "does blow up when portTypes are imported" do
      get_customer = subject.operations[:get_customer]

      get_customer[:input].should == "GetCustomer"
      get_customer[:namespace_identifier].should be_nil
    end

  end
end
