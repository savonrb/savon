require "spec_helper"

describe Savon::Service do
  before { @proxy = Savon::Service.new SpecHelper.some_endpoint }

  describe "SOAPFaultCodeXPath" do
    it "should include the XPath to the SOAP fault code for both SOAP 1+2" do
      Savon::Service::SOAPFaultCodeXPath[1].should be_true
      Savon::Service::SOAPFaultCodeXPath[2].should be_true
    end
  end

  describe "SOAPFaultMessageXPath" do
    it "should include the XPath to the SOAP fault message for both SOAP 1+2" do
      Savon::Service::SOAPFaultMessageXPath[1].should be_true
      Savon::Service::SOAPFaultMessageXPath[2].should be_true
    end
  end

  describe "initialize" do
    it "expects the endpoint URI as a String" do
      Savon::Service.new SpecHelper.some_endpoint
    end

    it "raises" do
      lambda { Savon::Service.new "invalid uri" }.should raise_error(URI::InvalidURIError)
    end
  end

  describe "response" do
    it "returns the Net::HTTPResponse of the last SOAP call" do
      @proxy.find_user
      @proxy.response.should be_a Net::HTTPResponse
    end
  end

  describe "wsdl" do
    it "returns the WSDL object" do
      @proxy.wsdl.should be_an_instance_of Savon::WSDL
    end

    it "always returns the same WSDL object" do 
      @proxy.wsdl.should equal @proxy.wsdl
    end
  end

  describe "respond_to?" do
    it "returns true for SOAP actions" do
      UserFixture.soap_actions.keys.each do |soap_action|
        @proxy.respond_to?(soap_action).should be_true
      end
    end

    it "delegates to super" do
      @proxy.respond_to?(:object_id).should be_true
    end
  end

  describe "method_missing" do
    it "raises a NoMethodError in case the SOAP action seems to be invalid" do
      lambda { @proxy.invalid_soap_action }.should raise_error(NoMethodError)
    end

    it "parses the SOAP response body for a '//return' node and returns the content as a Hash" do
      response = @proxy.find_user

      response["id"].should ==  UserFixture.soap_response_hash_id
      response["username"].should == UserFixture.soap_response_hash_username
      response["email"].should == UserFixture.soap_response_hash_email
      response["registered"].should == UserFixture.soap_response_hash_registered
    end

    it "raises a Savon::SOAPFault in case of a SOAP fault" do
      proxy = Savon::Service.new SpecHelper.soapfault_endpoint
      lambda { proxy.find_user }.should raise_error(Savon::SOAPFault)
    end

    it "raises a Savon::HTTPError in case of an HTTP error" do
      proxy = Savon::Service.new SpecHelper.httperror_endpoint
      lambda { proxy.find_user }.should raise_error(Savon::HTTPError)
    end

    it "accepts a block for custom response processing" do
      @proxy.find_user { |request| request.body }.should == UserFixture.user_response
    end

    it "accepts a Hash of parameters to be received by the SOAP service" do
      @proxy.find_user :id => { "$" => "666" }
      @proxy.http_request.body.should include "<id>666</id>"
    end

    describe "Hash configuration per request" do
      it "uses the value from :soap_body for the SOAP request body" do
        @proxy.find_user :soap_body => { :id => { "$" => 666 } }
        @proxy.http_request.body.should include "<id>666</id>"
      end

      it "uses the value from :soap_version to specify the SOAP version" do
        @proxy.find_user :soap_body => {}, :soap_version => 2
        Savon::Config.instance.soap_version.should == 2
      end

      it "handles WSSE authentication" do
        @proxy.find_user :soap_body => {}, :wsse => {
          :username => "thedude", :password => "secret"
        }

        request_body = @proxy.http_request.body
        request_body.should include *SpecHelper.wsse_security_nodes
        request_body.should include the_unencrypted_wsse_password
      end

      it "handles WSSE digest authentication" do
        @proxy.find_user :soap_body => {}, :wsse => {
          :username => "thedude", :password => "secret", :digest => true
        }

        request_body = @proxy.http_request.body
        request_body.should include *SpecHelper.wsse_security_nodes
        request_body.should_not include the_unencrypted_wsse_password
      end

      def the_unencrypted_wsse_password
        "<wsse:Password>#{savon_config.wsse_password}</wsse:Password>"
      end
    end

    it "converts parameter keys specified as Symbols to lowerCamelCase" do
      @proxy.find_user :totally_rad => { "$" => "true" }
      @proxy.http_request.body.should include "<totallyRad>true</totallyRad>"
    end

    it "does not convert parameter keys specified as Strings" do
      @proxy.find_user "totally_rad" => { "$" => "true" }
      @proxy.http_request.body.should include "<totally_rad>true</totally_rad>"
    end

    it "converts DateTime parameter values to SOAP datetime Strings" do
      @proxy.find_user :before => { "$" => DateTime.new(2012, 6, 11, 10, 42, 21) }
      @proxy.http_request.body.should include "<before>2012-06-11T10:42:21</before>"
    end

    it "converts parameter values responding to :to_datetime to SOAP datetime Strings" do
      datetime_singleton = Class.new
      def datetime_singleton.to_datetime
        DateTime.new(2012, 6, 11, 10, 42, 21)
      end

      @proxy.find_user :before => { "$" => datetime_singleton }
      @proxy.http_request.body.should include "<before>2012-06-11T10:42:21</before>"
    end

    it "converts parameter values responding to :to_s into Strings" do
      @proxy.find_user :before => { "$" => 2012 }, :with => { "$" => :superpowers }
      @proxy.http_request.body.should include "<before>2012</before>", "<with>superpowers</with>"
    end
  end

end