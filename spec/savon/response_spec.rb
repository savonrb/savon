require "spec_helper"

describe Savon::Response do

  let(:globals) { Savon::GlobalOptions.new }
  let(:locals)  { Savon::LocalOptions.new }

  describe ".new" do
    it "should raise a Savon::Fault in case of a SOAP fault" do
      lambda { soap_fault_response }.should raise_error(Savon::SOAPFault)
    end

    it "should not raise a Savon::Fault in case the default is turned off" do
      globals[:raise_errors] = false
      lambda { soap_fault_response }.should_not raise_error(Savon::SOAPFault)
    end

    it "should raise a Savon::HTTP::Error in case of an HTTP error" do
      lambda { soap_response :code => 500 }.should raise_error(Savon::HTTPError)
    end

    it "should not raise a Savon::HTTP::Error in case the default is turned off" do
      globals[:raise_errors] = false
      soap_response :code => 500
    end
  end

  describe "#success?" do
    before { globals[:raise_errors] = false }

    it "should return true if the request was successful" do
      soap_response.should be_a_success
    end

    it "should return false if there was a SOAP fault" do
      soap_fault_response.should_not be_a_success
    end

    it "should return false if there was an HTTP error" do
      http_error_response.should_not be_a_success
    end
  end

  describe "#soap_fault?" do
    before { globals[:raise_errors] = false }

    it "should not return true in case the response seems to be ok" do
      soap_response.soap_fault?.should be_false
    end

    it "should return true in case of a SOAP fault" do
      soap_fault_response.soap_fault?.should be_true
    end
  end

  describe "#http_error?" do
    before { globals[:raise_errors] = false }

    it "should not return true in case the response seems to be ok" do
      soap_response.http_error?.should_not be_true
    end

    it "should return true in case of an HTTP error" do
      soap_response(:code => 500).http_error?.should be_true
    end
  end

  describe "#header" do
    it "should return the SOAP response header as a Hash" do
      response = soap_response :body => Fixture.response(:header)
      response.header.should include(:session_number => "ABCD1234")
    end

    it "should throw an exception when the response header isn't parsable" do
      lambda { invalid_soap_response.header }.should raise_error Savon::InvalidResponseError
    end
  end

  %w(body to_hash).each do |method|
    describe "##{method}" do
      it "should return the SOAP response body as a Hash" do
        soap_response.send(method)[:authenticate_response][:return].should ==
          Fixture.response_hash(:authentication)[:authenticate_response][:return]
      end

      it "should return a Hash for a SOAP multiRef response" do
        hash = soap_response(:body => Fixture.response(:multi_ref)).send(method)

        hash[:list_response].should be_a(Hash)
        hash[:multi_ref].should be_an(Array)
      end

      it "should add existing namespaced elements as an array" do
        hash = soap_response(:body => Fixture.response(:list)).send(method)

        hash[:multi_namespaced_entry_response][:history].should be_a(Hash)
        hash[:multi_namespaced_entry_response][:history][:case].should be_an(Array)
      end
    end
  end

  describe "#to_array" do
    context "when the given path exists" do
      it "should return an Array containing the path value" do
        soap_response.to_array(:authenticate_response, :return).should ==
          [Fixture.response_hash(:authentication)[:authenticate_response][:return]]
      end

      it "should properly return FalseClass values [#327]" do
        body = Gyoku.xml(:envelope => { :body => { :return => { :success => false } } })
        soap_response(:body => body).to_array(:return, :success).should == [false]
      end
    end

    context "when the given path returns nil" do
      it "should return an empty Array" do
        soap_response.to_array(:authenticate_response, :undefined).should == []
      end
    end

    context "when the given path does not exist at all" do
      it "should return an empty Array" do
        soap_response.to_array(:authenticate_response, :some, :undefined, :path).should == []
      end
    end
  end

  describe "#hash" do
    it "should return the complete SOAP response XML as a Hash" do
      response = soap_response :body => Fixture.response(:header)
      response.hash[:envelope][:header][:session_number].should == "ABCD1234"
    end
  end

  describe "#to_xml" do
    it "should return the raw SOAP response body" do
      soap_response.to_xml.should == Fixture.response(:authentication)
    end
  end

  describe "#doc" do
    it "returns a Nokogiri::XML::Document for the SOAP response XML" do
      soap_response.doc.should be_a(Nokogiri::XML::Document)
    end
  end

  describe "#xpath" do
    it "permits XPath access to elements in the request" do
      soap_response.xpath("//client").first.inner_text.should == "radclient"
      soap_response.xpath("//ns2:authenticateResponse/return/success").first.inner_text.should == "true"
    end
  end

  describe "#http" do
    it "should return the HTTPI::Response" do
      soap_response.http.should be_an(HTTPI::Response)
    end
  end

  def soap_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options
    http_response = HTTPI::Response.new(response[:code], response[:headers], response[:body])

    Savon::Response.new(http_response, globals, locals)
  end

  def soap_fault_response
    soap_response :code => 500, :body => Fixture.response(:soap_fault)
  end

  def http_error_response
    soap_response :code => 404, :body => "Not found"
  end

  def invalid_soap_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => "I'm not SOAP" }
    response = defaults.merge options
    http_response = HTTPI::Response.new(response[:code], response[:headers], response[:body])

    Savon::Response.new(http_response, globals, locals)
  end

end
