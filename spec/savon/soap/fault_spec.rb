require "spec_helper"

describe Savon::SOAP::Fault do
  let(:soap_fault) { Savon::SOAP::Fault.new new_response(:body => Fixture.response(:soap_fault)) }
  let(:soap_fault2) { Savon::SOAP::Fault.new new_response(:body => Fixture.response(:soap_fault12)) }
  let(:another_soap_fault) { Savon::SOAP::Fault.new new_response(:body => Fixture.response(:another_soap_fault)) }
  let(:no_fault) { Savon::SOAP::Fault.new new_response }

  it "should be a Savon::Error" do
    Savon::SOAP::Fault.should < Savon::Error
  end

  describe "#http" do
    it "should return the HTTPI::Response" do
      soap_fault.http.should be_an(HTTPI::Response)
    end
  end

  describe "#present?" do
    it "should return true if the HTTP response contains a SOAP 1.1 fault" do
      soap_fault.should be_present
    end

    it "should return true if the HTTP response contains a SOAP 1.2 fault" do
      soap_fault2.should be_present
    end

    it "should return true if the HTTP response contains a SOAP fault with different namespaces" do
      another_soap_fault.should be_present
    end

    it "should return false unless the HTTP response contains a SOAP fault" do
      no_fault.should_not be_present
    end
  end

  [:message, :to_s].each do |method|
    describe "##{method}" do
      it "should return an empty String unless a SOAP fault is present" do
        no_fault.send(method).should == ""
      end

      it "should return a SOAP 1.1 fault message" do
        soap_fault.send(method).should == "(soap:Server) Fault occurred while processing."
      end

      it "should return a SOAP 1.2 fault message" do
        soap_fault2.send(method).should == "(soap:Sender) Sender Timeout"
      end

      it "should return a SOAP fault message (with different namespaces)" do
        another_soap_fault.send(method).should == "(ERR_NO_SESSION) Wrong session message"
      end
    end
  end

  describe "#to_hash" do
    it "should return the SOAP response as a Hash unless a SOAP fault is present" do
      no_fault.to_hash[:authenticate_response][:return][:success].should be_true
    end

    it "should return a SOAP 1.1 fault as a Hash" do
      soap_fault.to_hash.should == {
        :fault => {
          :faultstring => "Fault occurred while processing.",
          :faultcode   => "soap:Server"
        }
      }
    end

    it "should return a SOAP 1.2 fault as a Hash" do
      soap_fault2.to_hash.should == {
        :fault => {
          :detail => { :max_time => "P5M" },
          :reason => { :text => "Sender Timeout" },
          :code   => { :value => "soap:Sender", :subcode => { :value => "m:MessageTimeout" } }
        }
      }
    end
  end

  def new_response(options = {})
    defaults = { :code => 500, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end

end
