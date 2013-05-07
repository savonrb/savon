require "spec_helper"

describe Wasabi::Document do
  context "with: email_validation.wsdl" do

    subject(:document) { Wasabi::Document.new fixture(:email_validation).read }

    it 'works with Array\'s of anyType elements which don\'t have a type attribute'  do
      expect(document.type_definitions).to eq(
        [
          [["AdvancedVerifyEmailResponse", "AdvancedVerifyEmailResult"], "ReturnIndicator"],
          [["VerifyEmailResponse",         "VerifyEmailResult"],         "ReturnIndicator"],
          [["ReturnCodesResponse",         "ReturnCodesResult"],         "ArrayOfAnyType" ]
        ]
      )
    end

  end
end
