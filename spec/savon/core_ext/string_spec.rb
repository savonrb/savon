require "spec_helper"

describe String do

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

end
