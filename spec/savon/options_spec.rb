require "spec_helper"

describe Savon::Options do

  subject(:options) { Savon::Options.new }

  it "only contains default values for existing options" do
    Savon::Options::DEFAULTS.keys.each do |option|
      included_in_global = Savon::Options::GLOBAL.include? option
      included_in_request = Savon::Options::REQUEST.include? option

      unless included_in_global || included_in_request
        fail "Expected global or request options to contain default value for #{option.inspect}"
      end
    end
  end

  it "can set and retrieve values from a given scope" do
    options.set(:global, :logger => :some_logger)

    option = options.get(:global, :logger)
    expect(option).to eq(:some_logger)
  end

  it "returns a default value for :soap_version" do
    soap_version = options.get(:global, :soap_version)
    expect(soap_version).to eq(1)
  end

  describe "#set" do
    it "validates the scope" do
      expect { options.set(:invalid_scope, {}) }.
        to raise_error(ArgumentError, /Invalid option scope: :invalid_scope/)
    end

    it "validates the options" do
      expect { options.set(:global, :invalid_option => 111) }.
        to raise_error(ArgumentError, /Unknown global option\(s\): \[:invalid_option\]/)
    end
  end

  describe "#get" do
    it "validates the scope" do
      expect { options.get(:invalid_scope, :invalid_option) }.
        to raise_error(ArgumentError, /Invalid option scope: :invalid_scope/)
    end

    it "validates the option" do
      expect { options.get(:request, :invalid_option) }.
        to raise_error(ArgumentError, /Unknown request option: :invalid_option/)
    end
  end

end
