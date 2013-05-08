require "spec_helper"

describe Wasabi::Parser do
  context "with: geotrust.wsdl" do

    subject(:parser) { Wasabi::Parser.new Nokogiri::XML(xml) }

    let(:xml) { fixture(:geotrust).read }

    it "returns the #service_name attribute" do
      parser.service_name.should == "queryDefinitions"
    end

  end
end
