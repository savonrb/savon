require "spec_helper"

describe String do

  describe "self.random" do
    it "returns a random 100-character String" do
      String.random.should be_a(String)
      String.random.length.should == 100
    end

    it "returns a random String of a given length" do
      String.random(50).should be_a(String)
      String.random(50).length.should == 50
    end
  end

  describe "snakecase" do
    it "converts a lowerCamelCase String to snakecase" do
      "lowerCamelCase".snakecase.should == "lower_camel_case"
    end

    it "converts period characters to underscores" do
      "User.GetEmail".snakecase.should == "user_get_email"
    end
  end

  describe "lower_camelcase" do
    it "converts a snakecase String to lowerCamelCase" do
      "lower_camel_case".lower_camelcase.should == "lowerCamelCase"
    end
  end

  describe "starts_with?" do
    it "should return whether it starts with a given suffix" do
      "authenticate".starts_with?("auth").should be_true
      "authenticate".starts_with?("cate").should be_false
    end
  end

  describe "ends_with?" do
    it "should return whether it ends with a given suffix" do
      "authenticate!".ends_with?("!").should be_true
      "authenticate".ends_with?("cate").should be_true
      "authenticate".ends_with?("?").should be_false
    end
  end

  describe "strip_namespace" do
    it "strips the namespace from a namespaced String" do
      "ns:customer".strip_namespace.should == "customer"
    end

    it "returns the original String for a String without namespace" do
      "customer".strip_namespace.should == "customer"
    end
  end

  describe "map_soap_response" do
    it "returns a DateTime Object for Strings matching the xs:dateTime format" do
      "2012-03-22T16:22:33".map_soap_response.should ==
        DateTime.new(2012, 03, 22, 16, 22, 33)
    end

    it "returns true for Strings matching 'true'" do
      "true".map_soap_response.should be_true
    end

    it "returns false for Strings matching 'false'" do
      "false".map_soap_response.should be_false
    end

    it "defaults to return the original value" do
      "whatever".map_soap_response.should == "whatever"
    end
  end

  describe "to_soap_key" do
    it "removes exclamation marks from the end of the String" do
      "value".to_soap_key.should == "value"
      "value!".to_soap_key.should == "value"
    end
  end

  describe "to_soap_value" do
    it "should return the String value and escape special characters" do
      "string".to_soap_value.should == "string"
      "<tag>".to_soap_value.should == "&lt;tag&gt;"
      "at&t".to_soap_value.should == "at&amp;t"
      '"quotes"'.to_soap_value.should == "&quot;quotes&quot;"
    end
  end

  describe "to_soap_value!" do
    it "should just return the String value without escaping special characters" do
      "<tag>".to_soap_value!.should == "<tag>"
    end
  end

end
