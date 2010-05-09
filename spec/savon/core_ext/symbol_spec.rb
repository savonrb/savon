require "spec_helper"

describe Symbol do

  describe "to_soap_key" do
    it "converts the Symbol from snake_case to a lowerCamelCase String" do
      :lower_camel_case.to_soap_key.should == "lowerCamelCase"
      :lower_camel_case!.to_soap_key.should == "lowerCamelCase"
    end
  end

end
