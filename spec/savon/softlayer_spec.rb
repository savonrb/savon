# frozen_string_literal: true
require "spec_helper"

describe Savon::Builder do

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
      expect(builder.to_s).to eq('<?xml version="1.0" encoding="UTF-8"?><env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="http://api.service.softlayer.com/soap/v3/" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"><env:Body><createObject><templateObject xsi:type="tns:SoftLayer_Brand"><longName>Zertico LLC Reseller</longName></templateObject></createObject></env:Body></env:Envelope>')
    end
  end
end
