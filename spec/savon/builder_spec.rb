require "spec_helper"

describe Savon::Builder do

  subject(:builder) { Savon::Builder.new(:authenticate, wsdl, globals, locals) }

  let(:globals)     { Savon::GlobalOptions.new(:namespace_identifier => :tns) }
  let(:locals)      { Savon::LocalOptions.new(:message_tag => :authenticate) }
  let(:wsdl)        { Wasabi::Document.new Fixture.wsdl(:authentication) }
  let(:no_wsdl)     { Wasabi::Document.new }

  describe "#to_s" do
    it "includes the target namespace from the WSDL" do
      expect(builder.to_s).to include('xmlns:tns="http://v1_0.ws.auth.order.example.com/"')
    end

    it "includes the target namespace from the global :namespace if it's available" do
      globals[:namespace] = "http://v1.example.com"
      expect(builder.to_s).to include('xmlns:tns="http://v1.example.com"')
    end

    it "includes the local :message_tag if available" do
      locals[:message_tag] = "doAuthenticate"
      expect(builder.to_s).to include("<tns:doAuthenticate>")
    end

    it "includes the message tag from the WSDL if its available" do
      expect(builder.to_s).to include("<tns:authenticate>")
    end

    it "includes a message tag created by Gyoku if both option and WSDL are missing" do
      # TODO: why do i have to set this? needs to be cleaned up! [dh, 2012-12-13]
      globals[:namespace] = "http://v1.example.com"

      locals = Savon::LocalOptions.new
      builder = Savon::Builder.new(:authenticate, no_wsdl, globals, locals)

      expect(builder.to_s).to include("<tns:authenticate>")
    end
  end

end
