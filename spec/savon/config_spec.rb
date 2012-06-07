require "spec_helper"

describe Savon::Config do

  describe "#clone" do
    subject do
      config = Savon::Config.new
      config._logger = Savon::Logger.new
      config
    end

    it "clones the logger" do
      logger = subject.logger
      clone = subject.clone

      logger.should_not equal(clone.logger)
    end
  end

end
