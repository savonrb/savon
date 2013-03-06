require "spec_helper"

describe Savon::Builder do

  subject(:builder) { Savon::Builder.new(:authenticate, wsdl, globals, locals) }

  let(:globals)     { Savon::GlobalOptions.new }
  let(:locals)      { Savon::LocalOptions.new }
  let(:wsdl)        { Wasabi::Document.new Fixture.wsdl(:authentication) }
  let(:no_wsdl)     { Wasabi::Document.new }

  describe "#pretty" do
    it "returns the pretty printed request" do
      expect(builder.pretty).to include("<env:Body>\n    <tns:authenticate/>")
    end
  end

  describe "#to_s" do
    it "includes the global :env_namespace if it's available" do
      globals[:env_namespace] = :soapenv
      expect(builder.to_s).to include("<soapenv:Envelope")
    end

    it "defaults to include the default envelope namespace of :env" do
      expect(builder.to_s).to include("<env:Envelope")
    end

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
      globals[:namespace] = "http://v1.example.com"

      locals = Savon::LocalOptions.new
      builder = Savon::Builder.new(:authenticate, no_wsdl, globals, locals)

      expect(builder.to_s).to include("<wsdl:authenticate>")
    end

    it "uses the global :namespace_identifier option if it's available" do
      globals[:namespace_identifier] = :v1
      expect(builder.to_s).to include("<v1:authenticate>")
    end

    it "uses the WSDL's namespace_identifier if the global option was not specified" do
      expect(builder.to_s).to include("<tns:authenticate>")
    end

    it "uses the default :wsdl identifier if both option and WSDL were not specified" do
      globals[:namespace] = "http://v1.example.com"

      builder = Savon::Builder.new(:authenticate, no_wsdl, globals, locals)
      expect(builder.to_s).to include("<wsdl:authenticate>")
    end

    it "uses the global :element_form_default option if it's available " do
      globals[:element_form_default] = :qualified
      locals[:message] = { :username => "luke", :password => "secret" }

      expect(builder.to_s).to include("<tns:username>luke</tns:username>")
    end

    it "uses the WSDL's element_form_default value if the global option was set specified" do
      locals[:message] = { :username => "luke", :password => "secret" }
      wsdl.element_form_default = :qualified

      expect(builder.to_s).to include("<tns:username>luke</tns:username>")
    end

  end

end
