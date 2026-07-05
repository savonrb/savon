# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::Options do
  describe Savon::GlobalOptions do
    it "marks options passed to the constructor as explicit" do
      # :strip_namespaces is passed with its default value and tracked
      # because we record the caller's intent, not a diff against the
      # built-in defaults.
      globals = described_class.new(strip_namespaces: true)

      expect(globals.explicit?(:strip_namespaces)).to be(true)
    end

    it "does not mark built-in defaults as explicit" do
      globals = described_class.new

      expect(globals.explicit?(:strip_namespaces)).to be(false)
    end

    it "marks options assigned via []= as explicit" do
      globals = described_class.new
      globals[:soap_version] = 2

      expect(globals.explicit?(:soap_version)).to be(true)
    end

    it "marks options set through a block as explicit" do
      globals = described_class.new
      Savon::BlockInterface.new(globals).evaluate(proc { soap_version 2 })

      expect(globals.explicit?(:soap_version)).to be(true)
    end

    it "does not mark other options as explicit when a block sets one" do
      globals = described_class.new
      Savon::BlockInterface.new(globals).evaluate(proc { soap_version 2 })

      expect(globals.explicit?(:log)).to be(false)
    end
  end

  describe Savon::LocalOptions do
    it "marks options passed to the constructor as explicit" do
      locals = described_class.new(advanced_typecasting: true)

      expect(locals.explicit?(:advanced_typecasting)).to be(true)
    end

    it "does not mark built-in defaults as explicit" do
      locals = described_class.new

      expect(locals.explicit?(:advanced_typecasting)).to be(false)
    end
  end
end
