require "spec_helper"

describe URI::HTTP do

  describe "ssl?" do
    it "returns true for https URI's" do
      URI("https://example.com").ssl?.should be_true
    end

    it "returns false for non-https URI's" do
      URI("http://example.com").ssl?.should be_false
    end

    it "returns nil for invalid URI's without a scheme" do
      URI("example").ssl?.should be_nil
    end
  end

end
