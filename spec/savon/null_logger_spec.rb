require "spec_helper"

describe Savon::NullLogger do

  let(:logger) { subject }

  it "does not log messages" do
    logger.subject.expects(logger.level).never
    logger.log Fixture.response(:authentication)
  end

  it "does not log filtered messages" do
    logger.subject.expects(logger.level).never
    logger.log_filtered Fixture.response(:authentication)
  end

end
