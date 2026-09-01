# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::Addressing do
  subject(:addressing) { described_class.new(enabled: enabled, action: action, to: to) }

  let(:enabled) { true }
  let(:action)  { "http://taxcloud.net/VerifyAddress" }
  let(:to)      { URI.parse("https://api.taxcloud.net/1.0/TaxCloud.asmx") }

  it "declares the WS-Addressing 1.0 namespace" do
    expect(described_class::NAMESPACE).to eq("http://www.w3.org/2005/08/addressing")
  end

  describe "#enabled?" do
    it "returns true when addressing is enabled" do
      expect(addressing.enabled?).to be(true)
    end

    context "when addressing is not enabled" do
      let(:enabled) { nil }

      it "returns false" do
        expect(addressing.enabled?).to be(false)
      end
    end
  end

  describe "#namespace_attributes" do
    it "declares the wsa prefix when enabled" do
      expect(addressing.namespace_attributes).to eq(
        "xmlns:wsa" => "http://www.w3.org/2005/08/addressing"
      )
    end

    context "when addressing is not enabled" do
      let(:enabled) { false }

      it "declares nothing" do
        expect(addressing.namespace_attributes).to eq({})
      end
    end
  end

  describe "#to_xml" do
    it "emits wsa:Action with the action" do
      expect(addressing.to_xml).to include(
        "<wsa:Action>http://taxcloud.net/VerifyAddress</wsa:Action>"
      )
    end

    it "emits wsa:To with the destination" do
      expect(addressing.to_xml).to include(
        "<wsa:To>https://api.taxcloud.net/1.0/TaxCloud.asmx</wsa:To>"
      )
    end

    it "emits wsa:MessageID as a urn:uuid" do
      expect(addressing.to_xml).to match(
        %r{<wsa:MessageID>urn:uuid:\h{8}-\h{4}-\h{4}-\h{4}-\h{12}</wsa:MessageID>}
      )
    end

    it "generates a fresh MessageID on every rendering" do
      first  = addressing.to_xml
      second = addressing.to_xml

      expect(second).not_to eq(first)
    end

    # A nil action means the caller explicitly disabled the SOAPAction,
    # so the element is emitted with xsi:nil rather than being dropped.
    context "with a nil action" do
      let(:action) { nil }

      it "emits an xsi:nil wsa:Action" do
        expect(addressing.to_xml).to include('<wsa:Action xsi:nil="true"/>')
      end
    end

    context "when addressing is not enabled" do
      let(:enabled) { false }

      it "emits nothing" do
        expect(addressing.to_xml).to eq("")
      end
    end

    # A disabled Addressing needs no action or destination, so both can be omitted.
    context "when constructed disabled without action and destination" do
      subject(:addressing) { described_class.new(enabled: false) }

      it "emits nothing" do
        expect(addressing.to_xml).to eq("")
      end
    end

    it "does not mutate the destination it renders" do
      addressing.to_xml

      expect(to.to_s).to eq("https://api.taxcloud.net/1.0/TaxCloud.asmx")
    end
  end
end
