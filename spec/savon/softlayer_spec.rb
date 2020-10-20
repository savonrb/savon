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
      expect(builder.to_s).to include('<env:Envelope')
    end
  end
end
