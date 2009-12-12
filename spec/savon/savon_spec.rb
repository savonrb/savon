require "spec_helper"

describe Savon do

  it "contains an Array of supported SOAP versions" do
    Savon::SOAPVersions.should be_an Array
    Savon::SOAPVersions.should_not be_empty
  end

  it "contains the xs:dateTime format" do
    Savon::SOAPDateTimeFormat.should be_a String
    Savon::SOAPDateTimeFormat.should_not be_empty

    UserFixture.datetime_object.strftime(Savon::SOAPDateTimeFormat).
      should == UserFixture.datetime_string
  end

  it "contains a Regexp matching the xs:dateTime format" do
    Savon::SOAPDateTimeRegexp.should be_a Regexp
    (Savon::SOAPDateTimeRegexp === UserFixture.datetime_string).
      should be_true
  end

end
