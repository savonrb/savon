require "spec_helper"

describe Savon::Logger do

  let(:logger)                  { subject }
  let(:message)                 { "<?xml version='1.0'?><hello>world</hello>" }
  let(:pretty_message)          { Nokogiri::XML(message) }
  let(:filtered_message)        { Nokogiri::XML("<?xml version='1.0'?><hello>***FILTERED***</hello>") }

  it "logs a given message" do
    logger.subject.expects(logger.level).with(message)
    logger.log(message)
  end

  it "logs a given message (pretty)" do
    logger.subject.expects(logger.level).with(pretty_message.to_xml(:indent => 2))
    logger.log(message, :pretty => true)
  end

  it "logs a given message (filtered)" do
    logger.subject.expects(logger.level).with(filtered_message.to_s)
    logger.filter << :hello
    warn logger.log(message, :filter => true)
  end

  it "logs a given message (pretty and filtered)" do
    logger.subject.expects(logger.level).with(filtered_message.to_xml(:indent => 2))
    logger.filter << :hello
    logger.log(message, :pretty => true, :filter => true)
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
