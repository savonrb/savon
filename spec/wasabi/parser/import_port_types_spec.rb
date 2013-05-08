require "spec_helper"

describe Wasabi::Parser do
  context "with: import_port_types.wsdl" do

    subject(:parser) { Wasabi::Parser.new Nokogiri::XML(xml) }

    let(:xml) { fixture(:import_port_types).read }

    it "does blow up when portTypes are imported" do
      operation = parser.operations[:get_customer]

      operation.input.should == "GetCustomer"
      operation.nsid.should be_nil
    end

  end
end
