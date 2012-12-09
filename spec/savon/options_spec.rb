require "spec_helper"

describe Savon::Options do

  subject(:options) { Savon::Options.new_with_defaults }

  describe "#add" do
    it "adds a single value to a given option in a given scope" do
      options.add :global, :soap_version, 2
      soap_version = options.get(:global, :soap_version)

      expect(soap_version).to eq(2)
    end
  end

  describe "#merge" do
    it "merges two Option objects and returns a new one" do
      options = self.options
      new_options = options.merge(:global, :logger => :some_logger, :soap_version => 2)

      expect(options.object_id).not_to eq(new_options.object_id)
      expect(new_options.logger).to eq(:some_logger)
      expect(new_options.soap_version).to eq(2)
    end
  end

  describe "#get" do
    it "returns an option from a given scope" do
      soap_version = options.get(:global, :soap_version)
      expect(soap_version).to eq(1)
    end
  end

  context "defaults" do
    it "memoizes the default values" do
      options = self.options

      expect(options.logger).to equal(options.logger)
      expect(options.encoding).to equal(options.encoding)
    end

    it "returns a default value for the global :encoding option" do
      encoding = options.get(:global, :encoding)
      expect(encoding).to eq("UTF-8")
    end

    it "returns a default value for the global :soap_version option" do
      soap_version = options.get(:global, :soap_version)
      expect(soap_version).to eq(1)
    end

    it "returns a default value for the global :logger option" do
      logger = options.get(:global, :logger)
      expect(logger).to be_a(Savon::Logger)
    end

    it "returns a shim for the global :hooks option" do
      hooks = options.get(:global, :hooks)
      expect(hooks).to respond_to(:fire)
    end
  end

  describe "#merge" do
    it "validates the scope" do
      expect { options.merge(:invalid_scope, {}) }.
        to raise_error(ArgumentError, /Invalid option scope: :invalid_scope/)
    end

    it "validates the options" do
      expect { options.merge(:global, :invalid_option => 111) }.
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
