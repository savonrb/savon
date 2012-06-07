require "spec_helper"

describe Savon::SOAP do

  it "should contain the SOAP namespace for each supported SOAP version" do
    Savon::SOAP::VERSIONS.each do |soap_version|
      Savon::SOAP::NAMESPACE[soap_version].should be_a(String)
      Savon::SOAP::NAMESPACE[soap_version].should_not be_empty
    end
  end

  it "should contain a Rage of supported SOAP versions" do
    Savon::SOAP::VERSIONS.should == (1..2)
  end

end
