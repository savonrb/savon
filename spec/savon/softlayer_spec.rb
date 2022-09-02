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

      expected_namespaces = {
        'xmlns'           => "http://schemas.xmlsoap.org/wsdl/",
        'xmlns:xsd'       => "http://www.w3.org/2001/XMLSchema",
        'xmlns:xsi'       => "http://www.w3.org/2001/XMLSchema-instance",
        'xmlns:tns'       => "http://api.service.softlayer.com/soap/v3/",
        'xmlns:env'       => "http://schemas.xmlsoap.org/soap/envelope/",
        'xmlns:soap'      => "http://schemas.xmlsoap.org/wsdl/soap/",
        'xmlns:soap-enc'  => "http://schemas.xmlsoap.org/soap/encoding/",
        'xmlns:wsdl'      => "http://schemas.xmlsoap.org/wsdl/"
      }

      locals = Savon::LocalOptions.new(message)
      builder = Savon::Builder.new(:create_object, wsdl, globals, locals)

      envelope = Nokogiri::XML(builder.to_s).xpath('./env:Envelope').first

      expect(envelope.namespaces).to match(expected_namespaces)
    end
  end
end
