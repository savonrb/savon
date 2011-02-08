require "spec_helper"

describe Time do

  describe "#xs_datetime" do
    let(:time) { Time.utc(2011, 01, 04, 13, 45, 55) }

    it "should return an xs:dateTime formatted String" do
      time.xs_datetime.should == "2011-01-04T13:45:55Z"
    end
  end

end
