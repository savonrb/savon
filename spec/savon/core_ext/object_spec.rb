require "spec_helper"

describe Object do

  describe "blank?" do
    it "returns true for Objects perceived to be blank" do
      ["", false, nil, [], {}].each do |object|
        object.should be_blank
      end
    end

    it "returns false for every other Object" do
      ["!blank", true, [:a], {:a => "b"}].each do |object|
        object.should_not be_blank
      end
    end
  end

  describe "to_soap_key" do
    it "calls to_s for every Object" do
      Object.to_soap_key.should == Object.to_s
    end
  end

  describe "to_soap_value" do
    it "returns an xs:dateTime compliant String for Objects responding to to_datetime" do
      singleton = Object.new
      def singleton.to_datetime
        UserFixture.datetime_object
      end

      singleton.to_soap_value.should == UserFixture.datetime_string
    end

    it "calls to_s unless the Object responds to to_datetime" do
      "value".to_soap_value.should == "value".to_s
    end
  end

end
