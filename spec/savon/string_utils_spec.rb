# frozen_string_literal: true
require "spec_helper"

RSpec.describe Savon::StringUtils do

  describe "snakecase" do
    it "lowercases one word CamelCase" do
      expect(Savon::StringUtils.snakecase("Merb")).to eq("merb")
    end

    it "makes one underscore snakecase two word CamelCase" do
      expect(Savon::StringUtils.snakecase("MerbCore")).to eq("merb_core")
    end

    it "handles CamelCase with more than 2 words" do
      expect(Savon::StringUtils.snakecase("SoYouWantContributeToMerbCore")).to eq("so_you_want_contribute_to_merb_core")
    end

    it "handles CamelCase with more than 2 capital letter in a row" do
      expect(Savon::StringUtils.snakecase("CNN")).to eq("cnn")
      expect(Savon::StringUtils.snakecase("CNNNews")).to eq("cnn_news")
      expect(Savon::StringUtils.snakecase("HeadlineCNNNews")).to eq("headline_cnn_news")
    end

    it "does NOT change one word lowercase" do
      expect(Savon::StringUtils.snakecase("merb")).to eq("merb")
    end

    it "leaves snake_case as is" do
      expect(Savon::StringUtils.snakecase("merb_core")).to eq("merb_core")
    end

    it "converts period characters to underscores" do
      expect(Savon::StringUtils.snakecase("User.GetEmail")).to eq("user_get_email")
    end
  end

end
