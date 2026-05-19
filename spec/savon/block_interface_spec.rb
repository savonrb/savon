# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::BlockInterface do
  subject(:interface) { described_class.new(target) }

  let(:target) { Object.new }

  describe "#evaluate" do
    context "when block arity > 0" do
      it "yields the target to the block" do
        received = nil
        interface.evaluate(->(t) { received = t })
        expect(received).to equal(target)
      end

      it "does not instance_eval the block" do
        yielded_self = nil
        outer_self = self
        interface.evaluate(->(_t) { yielded_self = self })
        expect(yielded_self).to equal(outer_self)
      end
    end

    context "when block arity == 0" do
      it "delegates method calls to the target" do
        target.define_singleton_method(:hello) do "world" end
        result = nil
        interface.evaluate(proc { result = hello })
        expect(result).to eq("world")
      end

      it "falls back to the original context when target does not respond" do
        def self.only_on_spec_context
          "from spec"
        end

        result = nil
        interface.evaluate(proc { result = only_on_spec_context })
        expect(result).to eq("from spec")
      end

      it "captures the caller's self via eval with location metadata" do
        outer_self = self
        interface.evaluate(proc {})
        expect(interface.instance_variable_get(:@original)).to equal(outer_self)
      end
    end
  end
end
