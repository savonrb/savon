require "spec_helper"

describe Array do

  describe "to_soap_xml" do
    describe "should return SOAP request compatible XML" do
      it "for an Array of Hashes" do
        hash, result = [{ :name => "Eve" }], "<findUser><name>Eve</name></findUser>"
        hash.to_soap_xml("findUser").should == result
      end

      it "for an Array of Strings and other Objects" do
        hash, result = [:id, :name], "<someValues>id</someValues><someValues>name</someValues>"
        hash.to_soap_xml("someValues").should == result
      end
    end
  end

end
