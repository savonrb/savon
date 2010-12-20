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

end
