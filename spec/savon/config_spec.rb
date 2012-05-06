require "spec_helper"

describe Savon::Config do

  it "defaults to log" do
    subject.log?.should be_true
  end

  it "can be configured to not log anything" do
    subject.log = false
    subject.log?.should be_false
  end

  context "when instructed to filter log messages" do
    before do
      subject.log = true
    end

    it "does not filter the message when no log filter was set" do
      subject.logger.expects(subject.log_level).with(Fixture.response(:authentication))
      subject.log(Fixture.response(:authentication), :filter)
    end

    it "filters element values" do
      subject.log_filter = ["logType", "logTime"]
      filtered_values = /Notes Log|2010-09-21T18:22:01|2010-09-21T18:22:07/

      subject.logger.expects(subject.log_level).with do |msg|
        msg !~ filtered_values &&
        msg.include?('<ns10:logTime>***FILTERED***</ns10:logTime>') &&
        msg.include?('<ns10:logType>***FILTERED***</ns10:logType>') &&
        msg.include?('<ns11:logTime>***FILTERED***</ns11:logTime>') &&
        msg.include?('<ns11:logType>***FILTERED***</ns11:logType>')
      end

      subject.log(Fixture.response(:list), :filter)
    end
  end

  it "defaults to the standard Logger" do
    subject.logger.should be_a(Logger)
  end

  it "can be configured to use a different logger" do
    MyLogger = Class.new
    subject.logger = MyLogger
    subject.logger.should == MyLogger
  end

  it "defaults to the :debug log level" do
    subject.log_level.should == :debug
  end

  it "can be configured to use a different log level" do
    subject.log_level = :info
    subject.log_level.should == :info
  end

  it "defaults to raise errors" do
    subject.raise_errors?.should be_true
  end

  it "can be configured to not raise errors" do
    subject.raise_errors = false
    subject.raise_errors?.should be_false
  end

  it "defaults to SOAP 1.1" do
    subject.soap_version.should == 1
  end

  it "can be configured for SOAP 1.2 services" do
    subject.soap_version = 2
    subject.soap_version.should == 2
  end

  it "raises in case of an invalid version" do
    lambda { subject.soap_version = 3 }.should raise_error(ArgumentError)
  end

end
