require "spec_helper"

describe DateTime do
  before do
    @datetime = DateTime.new 2012, 03, 22, 16, 22, 33
    @datetime_string = "2012-03-22T16:22:33Z"
  end

  describe "to_soap_value" do
    it "should return an xs:dateTime compliant String" do
      @datetime.to_soap_value.should == @datetime_string
    end
  end

  describe "to_soap_value!" do
    it "should act like :to_soap_value" do
      @datetime.to_soap_value.should == @datetime_string
    end
  end

end
