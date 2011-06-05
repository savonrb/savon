require "spec_helper"

describe String do

  describe "snakecase" do
    it "lowercases one word CamelCase" do
      "Merb".snakecase.should == "merb"
    end

    it "makes one underscore snakecase two word CamelCase" do
      "MerbCore".snakecase.should == "merb_core"
    end

    it "handles CamelCase with more than 2 words" do
      "SoYouWantContributeToMerbCore".snakecase.should == "so_you_want_contribute_to_merb_core"
    end

    it "handles CamelCase with more than 2 capital letter in a row" do
      "CNN".snakecase.should == "cnn"
      "CNNNews".snakecase.should == "cnn_news"
      "HeadlineCNNNews".snakecase.should == "headline_cnn_news"
    end

    it "does NOT change one word lowercase" do
      "merb".snakecase.should == "merb"
    end

    it "leaves snake_case as is" do
      "merb_core".snakecase.should == "merb_core"
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
    it "returns whether it starts with a given suffix" do
      "authenticate".starts_with?("auth").should be_true
      "authenticate".starts_with?("cate").should be_false
    end
  end

end
