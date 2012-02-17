require "spec_helper"

describe Wasabi::Document do

  subject { Wasabi::Document.new }

  describe ".validate_element_form_default!" do
    [:unqualified, :qualified].each do |value|
      it "does not raise for :#{value}" do
        expect { Wasabi::Document.validate_element_form_default!(value) }.to_not raise_error
      end
    end

    it "raises if given an invalid value" do
      error_msg = "Invalid value for elementFormDefault: invalid\n" +
                  "Must be one of: [:unqualified, :qualified]"

      expect { Wasabi::Document.validate_element_form_default!(:invalid) }.
        to raise_error(ArgumentError, error_msg)
    end
  end

  describe "#element_form_default" do
    it "defaults to :unqualified" do
      subject.element_form_default.should == :unqualified
    end

    [:unqualified, :qualified].each do |value|
      it "accepts :#{value}" do
        subject.element_form_default = value
        subject.element_form_default.should == value
      end
    end

    it "raises if set to an invalid value" do
      expect { subject.element_form_default = :invalid }.
        to raise_error(ArgumentError, /Invalid value for elementFormDefault/)
    end
  end

end
