require "spec_helper"

describe Wasabi do
  context "with: email_validation.wsdl" do

    subject(:wsdl) { Wasabi.new fixture(:email_validation).read }

    it 'works with Array\'s of anyType elements which don\'t have a type attribute'  do
      any_types = wsdl.schemas.complex_type('ArrayOfAnyType')

      expect(any_types.children).to eq([
        { :name => "anyType", :type => nil, :simple_type => true, :form => nil, :singular => false }
      ])
    end

  end
end
