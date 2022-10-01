# frozen_string_literal: true
require "spec_helper"

RSpec.describe Savon::Response do

  let(:globals) { Savon::GlobalOptions.new }
  let(:locals)  { Savon::LocalOptions.new }

  describe ".new" do
    it "should raise a Savon::Fault in case of a SOAP fault" do
      expect { soap_fault_response }.to raise_error(Savon::SOAPFault)
    end

    it "should not raise a Savon::Fault in case the default is turned off" do
      globals[:raise_errors] = false
      expect { soap_fault_response }.not_to raise_error
    end

    it "should raise a Savon::HTTP::Error in case of an HTTP error" do
      expect { soap_response :code => 500 }.to raise_error(Savon::HTTPError)
    end

    it "should not raise a Savon::HTTP::Error in case the default is turned off" do
      globals[:raise_errors] = false
      soap_response :code => 500
    end
  end

  describe "#success?" do
    before { globals[:raise_errors] = false }

    it "should return true if the request was successful" do
      expect(soap_response).to be_a_success
    end

    it "should return false if there was a SOAP fault" do
      expect(soap_fault_response).not_to be_a_success
    end

    it "should return false if there was an HTTP error" do
      expect(http_error_response).not_to be_a_success
    end
  end

  describe "#soap_fault?" do
    before { globals[:raise_errors] = false }

    it "should not return true in case the response seems to be ok" do
      expect(soap_response.soap_fault?).to be_falsey
    end

    it "should return true in case of a SOAP fault" do
      expect(soap_fault_response.soap_fault?).to be_truthy
    end
  end

  describe "#soap_fault" do
    before { globals[:raise_errors] = false }

    it "should return nil in case the response seems to be ok" do
      expect(soap_response.soap_fault).to be_nil
    end

    it "should return a SOAPFault in case of a SOAP fault" do
      expect(soap_fault_response.soap_fault).to be_a(Savon::SOAPFault)
    end
  end

  describe "#http_error?" do
    before { globals[:raise_errors] = false }

    it "should not return true in case the response seems to be ok" do
      expect(soap_response.http_error?).not_to be_truthy
    end

    it "should return true in case of an HTTP error" do
      expect(soap_response(:code => 500).http_error?).to be_truthy
    end
  end

  describe "#http_error" do
    before { globals[:raise_errors] = false }

    it "should return nil in case the response seems to be ok" do
      expect(soap_response.http_error).to be_nil
    end

    it "should return a HTTPError in case of an HTTP error" do
      expect(soap_response(:code => 500).http_error).to be_a(Savon::HTTPError)
    end
  end

  describe "#header" do
    it "should return the SOAP response header as a Hash" do
      response = soap_response :body => Fixture.response(:header)
      expect(response.header).to include(:session_number => "ABCD1234")
    end

    it 'respects the global :strip_namespaces option' do
      globals[:strip_namespaces] = false

      response_with_header = soap_response(:body => Fixture.response(:header))
      header = response_with_header.header

      expect(header).to be_a(Hash)

      # notice: :session_number is a snake_case Symbol without namespaces,
      # but the Envelope and Header elements are qualified.
      expect(header.keys).to include(:session_number)
    end

    it 'respects the global :convert_response_tags_to option' do
      globals[:convert_response_tags_to] = lambda { |key| key.upcase }

      response_with_header = soap_response(:body => Fixture.response(:header))
      header = response_with_header.header

      expect(header).to be_a(Hash)
      expect(header.keys).to include('SESSIONNUMBER')
    end

    it 'respects the global :convert_attributes_to option' do
      globals[:convert_attributes_to] = lambda { |k,v| [] }

      response_with_header = soap_response(:body => Fixture.response(:header))
      header = response_with_header.header

      expect(header).to be_a(Hash)
      expect(header.keys).to include(:session_number)
    end

    it "should throw an exception when the response header isn't parsable" do
      expect { invalid_soap_response.header }.to raise_error Savon::InvalidResponseError
    end
  end

  %w(body to_hash).each do |method|
    describe "##{method}" do
      it "should return the SOAP response body as a Hash" do
        expect(soap_response.send(method)[:authenticate_response][:return]).to eq(
          Fixture.response_hash(:authentication)[:authenticate_response][:return]
        )
      end

      it "should return a Hash for a SOAP multiRef response" do
        hash = soap_response(:body => Fixture.response(:multi_ref)).send(method)

        expect(hash[:list_response]).to be_a(Hash)
        expect(hash[:multi_ref]).to be_an(Array)
      end

      it "should add existing namespaced elements as an array" do
        hash = soap_response(:body => Fixture.response(:list)).send(method)

        expect(hash[:multi_namespaced_entry_response][:history]).to be_a(Hash)
        expect(hash[:multi_namespaced_entry_response][:history][:case]).to be_an(Array)
      end

      it 'respects the global :strip_namespaces option' do
        globals[:strip_namespaces] = false

        body = soap_response.body

        expect(body).to be_a(Hash)
        expect(body.keys).to include(:"ns2:authenticate_response")
      end

      it 'respects the global :convert_response_tags_to option' do
        globals[:convert_response_tags_to] = lambda { |key| key.upcase }

        body = soap_response.body

        expect(body).to be_a(Hash)
        expect(body.keys).to include('AUTHENTICATERESPONSE')
      end
    end
  end

  describe "#to_array" do
    context "when the given path exists" do
      it "should return an Array containing the path value" do
        expect(soap_response.to_array(:authenticate_response, :return)).to eq(
          [Fixture.response_hash(:authentication)[:authenticate_response][:return]]
        )
      end

      it "should properly return FalseClass values [#327]" do
        body = Gyoku.xml(:envelope => { :body => { :return => { :success => false } } })
        expect(soap_response(:body => body).to_array(:return, :success)).to eq([false])
      end
    end

    context "when the given path returns nil" do
      it "should return an empty Array" do
        expect(soap_response.to_array(:authenticate_response, :undefined)).to eq([])
      end
    end

    context "when the given path does not exist at all" do
      it "should return an empty Array" do
        expect(soap_response.to_array(:authenticate_response, :some, :undefined, :path)).to eq([])
      end
    end
  end

  describe "#hash" do
    it "should return the complete SOAP response XML as a Hash" do
      response = soap_response :body => Fixture.response(:header)
      expect(response.response_hash[:envelope][:header][:session_number]).to eq("ABCD1234")
    end
  end

  describe "#to_xml" do
    it "should return the raw SOAP response body" do
      expect(soap_response.to_xml).to eq(Fixture.response(:authentication))
    end
  end

  describe "#doc" do
    it "returns a Nokogiri::XML::Document for the SOAP response XML" do
      expect(soap_response.doc).to be_a(Nokogiri::XML::Document)
    end
  end

  describe "#xpath" do
    it "permits XPath access to elements in the request" do
      expect(soap_response.xpath("//client").first.inner_text).to eq("radclient")
      expect(soap_response.xpath("//ns2:authenticateResponse/return/success").first.inner_text).to eq("true")
    end
  end

  describe '#find' do
    it 'delegates to Nori#find to find child elements inside the Envelope' do
      result = soap_response.find('Body', 'authenticateResponse', 'return')

      expect(result).to be_a(Hash)
      expect(result.keys).to include(:authentication_value)
    end

    it 'fails correctly when envelope contains only string' do
      response = soap_response({ :body => Fixture.response(:no_body) })
      expect { response.find('Body') }.to raise_error Savon::InvalidResponseError
    end
  end

  describe "#http" do
    it "should return the HTTPI::Response" do
      expect(soap_response.http).to be_an(HTTPI::Response)
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
