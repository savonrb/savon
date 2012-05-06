require "spec_helper"

describe Savon do

  it "memoizes the global config" do
    Savon.config.should equal(Savon.config)
  end

  it "yields the global config to a block" do
    Savon.configure do |config|
      config.should equal(Savon.config)
    end
  end

end
