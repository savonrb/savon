require "spec_helper"

describe DateTime do

  describe "to_soap_value" do
    it "returns an xs:dateTime compliant String" do
      UserFixture.datetime_object.to_soap_value.
        should == UserFixture.datetime_string
    end
  end

end
