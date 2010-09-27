require "spec_helper"

describe Savon::SOAP do

  it "should contain the SOAP namespace for each supported SOAP version" do
    Savon::SOAP::Versions.each do |soap_version|
      Savon::SOAP::Namespace[soap_version].should be_a(String)
      Savon::SOAP::Namespace[soap_version].should_not be_empty
    end
  end

  it "should contain a Rage of supported SOAP versions" do
    Savon::SOAP::Versions.should == (1..2)
  end

  it "should contain the xs:dateTime format" do
    Savon::SOAP::DateTimeFormat.should be_a(String)
    Savon::SOAP::DateTimeFormat.should_not be_empty

    DateTime.new(2012, 03, 22, 16, 22, 33).strftime(Savon::SOAP::DateTimeFormat).
      should == "2012-03-22T16:22:33+00:00"
  end

  it "should contain a Regexp matching the xs:dateTime format" do
    Savon::SOAP::DateTimeRegexp.should be_a(Regexp)
    (Savon::SOAP::DateTimeRegexp === "2012-03-22T16:22:33").should be_true
  end

  describe ".version" do
    it "should default to SOAP 1.1" do
      Savon::SOAP.version.should == 1
    end

    it "should set the global SOAP version to use" do
      Savon::SOAP.version = 2
      Savon::SOAP.version.should == 2
      
      Savon::SOAP.version = Savon::SOAP::DefaultVersion  # reset to default
    end

    it "should raise an ArgumentError in case of an invalid version" do
      lambda { Savon::SOAP.version = 3 }.should raise_error(ArgumentError)
    end
  end
  
end
