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

  describe "storage and resolution" do
    it "returns the built-in default for options the caller did not set" do
      expect(Savon::GlobalOptions.new[:soap_version]).to eq(1)
    end

    it "returns the caller's value for options the caller set" do
      expect(Savon::GlobalOptions.new(soap_version: 2)[:soap_version]).to eq(2)
    end

    it "returns the caller's value even when it is nil" do
      globals = Savon::GlobalOptions.new(convert_response_tags_to: nil)

      expect(globals[:convert_response_tags_to]).to be_nil
    end

    it "is explicit for options the caller set to nil" do
      globals = Savon::GlobalOptions.new(empty_tag_value: nil)

      expect(globals.explicit?(:empty_tag_value)).to be(true)
    end

    it "includes defaulted options" do
      expect(Savon::GlobalOptions.new.include?(:log)).to be(true)
      expect(Savon::LocalOptions.new.include?(:advanced_typecasting)).to be(true)
    end

    it "does not include unset options without a default" do
      expect(Savon::GlobalOptions.new.include?(:wsdl)).to be(false)
    end

    it "returns the same default object on every read" do
      globals = Savon::GlobalOptions.new

      expect(globals[:namespaces]).to equal(globals[:namespaces])
    end

    it "gives a dup its own storage" do
      globals = Savon::GlobalOptions.new
      copy = globals.dup
      copy[:soap_version] = 2

      expect(globals[:soap_version]).to eq(1)
    end

    it "persists mutations of a read default" do
      globals = Savon::GlobalOptions.new
      globals[:namespaces]["xmlns:ins0"] = "http://example.com"

      expect(globals[:namespaces]).to eq("xmlns:ins0" => "http://example.com")
    end

    it "mirrors the :log default to HTTPI at client initialization" do
      HTTPI.log = true
      Savon.client(endpoint: "http://example.com", namespace: "http://v1.example.com")

      expect(HTTPI.log?).to be(false)
    ensure
      HTTPI.log = false
    end

    it "leaves HTTPI's logging state alone under transport: :faraday" do
      # HTTPI is not involved in a Faraday client, so its process-global
      # logging configuration stays whatever it was.
      HTTPI.log = true
      Savon.client(endpoint: "http://example.com", namespace: "http://v1.example.com",
                   transport: :faraday)

      expect(HTTPI.log?).to be(true)
    ensure
      HTTPI.log = false
    end
  end
end
