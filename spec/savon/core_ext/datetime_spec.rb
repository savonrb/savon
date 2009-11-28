require "spec_helper"

describe DateTime do

  describe "to_soap_value" do
    it "returns an xs:dateTime compliant String" do
      DateTime.new(2010, 11, 22, 11, 22, 33).to_soap_value.
        should == "2010-11-22T11:22:33"
    end
  end

end