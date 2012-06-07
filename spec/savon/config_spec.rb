require "spec_helper"

describe Savon::Config do

  let(:config) {
    config = Savon::Config.new
    config._logger = Savon::Logger.new
    config
  }

  describe "#clone" do
    it "clones the logger" do
      logger = config.logger
      clone = config.clone

      logger.should_not equal(clone.logger)
    end
  end

  it "allows to change the logger" do
    logger = Logger.new("/dev/null")
    config.logger = logger
    config._logger.subject.should equal(logger)
  end

  it "allows to change the log level" do
    config.log_level = :info
    config._logger.level.should == :info
  end

  it "allows to enable/disable logging" do
    config.log = false
    config._logger.should be_a(Savon::NullLogger)
    config.log = true
    config._logger.should be_a(Savon::Logger)
  end

end
