require "spec_helper"

describe Savon do

  it "provides a shortcut for creating a new client" do
    Savon.client("http://example.com").should be_a(Savon::Client)
  end

  it "memoizes the global config" do
    Savon.config.should equal(Savon.config)
  end

  it "yields the global config to a block" do
    Savon.configure do |config|
      config.should equal(Savon.config)
    end
  end

  describe ".config" do
    it "defaults to a log facade" do
      Savon.config.logger.should be_a(Savon::Logger)
    end

    it "defaults to raise errors" do
      Savon.config.raise_errors.should be_true
    end

    it "defaults to SOAP 1.1" do
      Savon.config.soap_version.should == 1
    end
  end

end
