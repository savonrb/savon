# frozen_string_literal: true
require "spec_helper"

RSpec.describe Savon::Builder do

  subject(:builder) { Savon::Builder.new(:create_object, wsdl, globals, locals) }

  let(:globals)     { Savon::GlobalOptions.new }
  # let(:locals)      { Savon::LocalOptions.new }
  let(:wsdl)        { Wasabi::Document.new Fixture.wsdl(:brand) }
  let(:no_wsdl)     { Wasabi::Document.new }

  describe "#to_s" do
    it "defaults to include the default envelope namespace of :env" do
      message = {
        :message=>{
          :template_object=>{
            :longName=>"Zertico LLC Reseller"
          }
        }
      }

      locals = Savon::LocalOptions.new(message)
      builder = Savon::Builder.new(:create_object, wsdl, globals, locals)

      envelope = Nokogiri::XML(builder.to_s).xpath('./env:Envelope').first

      expect(envelope.namespaces['xmlns:xsd']).to eq("http://www.w3.org/2001/XMLSchema")
      expect(envelope.namespaces['xmlns:xsi']).to eq("http://www.w3.org/2001/XMLSchema-instance")
      expect(envelope.namespaces['xmlns:tns']).to eq("http://api.service.softlayer.com/soap/v3/")
      expect(envelope.namespaces['xmlns:env']).to eq("http://schemas.xmlsoap.org/soap/envelope/")
      expect(envelope.namespaces['xmlns']).to eq("http://schemas.xmlsoap.org/wsdl/")
      expect(envelope.namespaces['xmlns:soap']).to eq("http://schemas.xmlsoap.org/wsdl/soap/")
      expect(envelope.namespaces['xmlns:soap-enc']).to eq("http://schemas.xmlsoap.org/soap/encoding/")
      expect(envelope.namespaces['xmlns:wsdl']).to eq("http://schemas.xmlsoap.org/wsdl/")
    end
  end
end
