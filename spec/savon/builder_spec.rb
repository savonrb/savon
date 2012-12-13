require "spec_helper"

describe Savon::Builder do

  subject(:builder) { Savon::Builder.new(:authenticate, wsdl, globals, locals) }

  let(:globals)     { Savon::GlobalOptions.new(:namespace_identifier => :tns) }
  let(:locals)      { Savon::LocalOptions.new(:message_tag => :authenticate) }
  let(:wsdl)        { Wasabi::Document.new Fixture.wsdl(:authentication) }

  describe "#to_s" do
    it "includes the target namespace from the WSDL" do
      expect(builder.to_s).to include('xmlns:tns="http://v1_0.ws.auth.order.example.com/"')
    end

    it "includes the target namespace from the global :namespace if it's available" do
      globals[:namespace] = "http://v1.example.com"
      expect(builder.to_s).to include('xmlns:tns="http://v1.example.com"')
    end
  end

end
