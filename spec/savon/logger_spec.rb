require "spec_helper"

describe Savon::Logger do

  let(:logger) { subject }

  it "logs a given message" do
    logger.subject.expects(logger.level).with(Fixture.response(:authentication))
    logger.log Fixture.response(:authentication)
  end

  describe "#log_filtered" do
    it "does not filter messages when no log filter was set" do
      logger.subject.expects(logger.level).with(Fixture.response(:authentication))
      logger.log_filtered Fixture.response(:authentication)
    end

    it "filters element values" do
      logger.filter = ["logType", "logTime"]
      filtered_values = /Notes Log|2010-09-21T18:22:01|2010-09-21T18:22:07/

      logger.subject.expects(logger.level).with do |msg|
        msg !~ filtered_values &&
        msg.include?('<ns10:logTime>***FILTERED***</ns10:logTime>') &&
        msg.include?('<ns10:logType>***FILTERED***</ns10:logType>') &&
        msg.include?('<ns11:logTime>***FILTERED***</ns11:logTime>') &&
        msg.include?('<ns11:logType>***FILTERED***</ns11:logType>')
      end

      logger.log_filtered Fixture.response(:list)
    end
  end

  it "defaults to wrap the standard Logger" do
    logger.subject.should be_a(Logger)
  end

  it "can be configured to use a different Logger" do
    MyLogger = Object.new
    logger.subject = MyLogger
    logger.subject.should == MyLogger
  end

  it "defaults to the :debug log level" do
    logger.level.should == :debug
  end

  it "can be configured to use a different log level" do
    logger.level = :info
    logger.level.should == :info
  end

end
