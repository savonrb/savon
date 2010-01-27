require "spec_helper"

describe DateTime do

  describe "to_soap_value" do
    it "returns an xs:dateTime compliant String" do
      DateTime.new(2012, 03, 22, 16, 22, 33).to_soap_value.
        should == "2012-03-22T16:22:33Z"
    end
  end

end
