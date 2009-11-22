require "spec_helper"

describe Savon::Service do
  before { @proxy = Savon::Service.new SpecHelper.some_endpoint }

  describe "method_missing" do

    it "raises a NoMethodError in case the SOAP action seems to be invalid" do
      lambda { @proxy.invalid_soap_action }.should raise_error(NoMethodError)
    end

    it "raises a Savon::SOAPFault in case of a SOAP fault" do
      proxy = Savon::Service.new SpecHelper.soapfault_endpoint
      lambda { proxy.find_user }.should raise_error(Savon::SOAPFault)
    end

    it "raises a Savon::HTTPError in case of an HTTP error" do
      proxy = Savon::Service.new SpecHelper.httperror_endpoint
      lambda { proxy.find_user }.should raise_error(Savon::HTTPError)
    end

  end

end