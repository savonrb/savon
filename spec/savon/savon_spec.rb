require "spec_helper"

describe Savon do

  it "contains an Array of supported SOAP versions" do
    Savon::SOAPVersions.should be_an Array
    Savon::SOAPVersions.should_not be_empty
  end

  it "contains the xs:dateTime format" do
    Savon::SOAPDateTimeFormat.should be_a String
    Savon::SOAPDateTimeFormat.should_not be_empty

    DateTime.new(2012, 03, 22, 16, 22, 33).strftime(Savon::SOAPDateTimeFormat).
      should == "2012-03-22T16:22:33"
  end

  it "contains a Regexp matching the xs:dateTime format" do
    Savon::SOAPDateTimeRegexp.should be_a Regexp
    (Savon::SOAPDateTimeRegexp === "2012-03-22T16:22:33").should be_true
  end

end
