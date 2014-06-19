require "spec_helper"

module Savon
  describe QualifiedMessage, "#to_hash" do

    context "if a key ends with !" do
      it "restores the ! in a key" do
        used_namespaces = {}
        key_converter = :camelcase
        types = {}

        message = described_class.new(types, used_namespaces, key_converter)
        resulting_hash = message.to_hash({:Metal! => "<Nice/>"}, ["Rock"])

        expect(resulting_hash).to eq({"Metal!" => "<Nice/>"})
      end
    end

  end
end
