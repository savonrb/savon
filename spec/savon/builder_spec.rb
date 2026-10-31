# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::Builder do
  subject(:builder) { described_class.new(:authenticate, wsdl, globals, locals) }

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

    it "includes a message tag created by Gyoku if both option and WSDL are missing" do
      globals[:namespace] = "http://v1.example.com"

      locals = Savon::LocalOptions.new
      builder = described_class.new(:authenticate, no_wsdl, globals, locals)

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

      builder = described_class.new(:authenticate, no_wsdl, globals, locals)
      expect(builder.to_s).to include("<wsdl:authenticate>")
    end

    it "uses the global :element_form_default option if it's available" do
      globals[:element_form_default] = :qualified
      locals[:message] = { username: "luke", password: "secret" }

      expect(builder.to_s).to include("<tns:username>luke</tns:username>")
    end

    it "uses the WSDL's element_form_default value if the global option was set specified" do
      locals[:message] = { username: "luke", password: "secret" }
      wsdl.element_form_default = :qualified

      expect(builder.to_s).to include("<tns:username>luke</tns:username>")
    end

    describe "#wsse_signature" do
      fixture_dir = File.join(File.dirname(__FILE__), '..', 'fixtures', 'ssl')

      subject(:signed_message_nn) { Nokogiri::XML(builder.to_s).remove_namespaces! }

      let(:signed_message) { Nokogiri::XML(builder.to_s) }
      let(:cert)        { File.join(fixture_dir, 'client_cert.pem') }
      let(:private_key) { File.join(fixture_dir, 'client_key.pem') }
      let(:signature) do
        Akami::WSSE::Signature.new(
          Akami::WSSE::Certs.new(
            cert_file: cert,
            private_key_file: private_key
          )
        )
      end
      let(:globals) { Savon::GlobalOptions.new(wsse_signature: signature) }

      it "contains a header" do
        expect(signed_message_nn.xpath('/Envelope/Header').size).to eq(1)
      end

      it "contains a wsse:Security" do
        expect(signed_message_nn.xpath('/Envelope/Header/Security').size).to eq(1)
      end

      it "has a Body[@wsu:Id]" do
        # must investigate: acts funny in mri ruby
        # expect(signed_message.xpath('//soapenv:Body', soapenv: "http://schemas.xmlsoap.org/soap/envelope/").attribute('ws:Id').value).to include('Body-')
        expect(signed_message_nn.xpath('//Body').attr('Id').value).to include('Body-')
      end

      it "signature should be valid" do
        certs = Akami::WSSE::Certs.new(cert_file: cert, private_key_file: private_key)
        signature_value = signed_message_nn.xpath('//SignatureValue').text
        signed_info_fragment = signed_message.xpath('//default:SignedInfo', default: "http://www.w3.org/2000/09/xmldsig#").to_xml
        data = Nokogiri::XML(signed_info_fragment) { |config| config.options = Nokogiri::XML::ParseOptions::NOBLANKS }
        data.root.default_namespace = 'http://www.w3.org/2000/09/xmldsig#'

        signed_info = data.canonicalize Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0

        signature = certs.private_key.sign(OpenSSL::Digest.new('SHA1'), signed_info)
        expect(Base64.encode64(signature).gsub("\n", '')).to eq(signature_value)
      end

      # The signature object is consumed in two places. The builder signs the
      # document and the header emits the wsse:BinarySecurityToken via Akami, so
      # both must resolve to the same effective signature. A local signature
      # overrides a global one.
      context "when a local :wsse_signature is also set" do
        let(:local_key) { OpenSSL::PKey::RSA.new(2048) }
        let(:local_cert) do
          OpenSSL::X509::Certificate.new.tap do |c|
            c.version    = 2
            c.serial     = 2
            c.subject    = OpenSSL::X509::Name.parse("/CN=local-signature")
            c.issuer     = c.subject
            c.public_key = local_key.public_key
            c.not_before = Time.now
            c.not_after  = Time.now + 3600
            c.sign(local_key, OpenSSL::Digest.new("SHA256"))
          end
        end
        let(:local_signature) do
          Akami::WSSE::Signature.new(
            Akami::WSSE::Certs.new(cert_string: local_cert.to_pem, private_key_string: local_key.to_pem)
          )
        end
        let(:locals) { Savon::LocalOptions.new(wsse_signature: local_signature) }

        it "embeds the local certificate, not the global one" do
          output       = builder.to_s
          local_token  = Base64.strict_encode64(local_cert.to_der)
          global_token = Base64.strict_encode64(OpenSSL::X509::Certificate.new(File.read(cert)).to_der)

          expect(output).to include(local_token)
          expect(output).not_to include(global_token)
        end
      end

      context "when the local :wsse_signature is false" do
        let(:locals) { Savon::LocalOptions.new(wsse_signature: false) }

        it "falls back to the global signature" do
          global_token = Base64.strict_encode64(OpenSSL::X509::Certificate.new(File.read(cert)).to_der)

          expect(builder.to_s).to include(global_token)
        end
      end
    end
  end

  describe "with a WSDL operation that has typed message parts" do
    let(:locals) { Savon::LocalOptions.new(message: { username: "luke", password: "secret" }) }

    before do
      wsdl.stubs(:soap_input).returns(
        "authenticate" => { "username" => %w[xsd string], "password" => %w[xsd string] }
      )
    end

    it "builds the body from the typed parts with xsi:type attributes" do
      body = builder.to_s

      expect(body).to include('<username xsi:type="xsd:string">luke</username>')
      expect(body).to include('<password xsi:type="xsd:string">secret</password>')
    end

    it "builds an empty body when no message was given" do
      builder = described_class.new(:authenticate, wsdl, globals, Savon::LocalOptions.new)

      expect(builder.to_s).not_to include("xsi:type")
    end
  end

  describe "with a blank :env_namespace" do
    before do
      globals[:env_namespace] = ""
    end

    it "omits the namespace prefix from the envelope" do
      body = builder.to_s

      expect(body).to include("<Envelope")
      expect(body).to include("<Body>")
      expect(body).not_to include("<env:Envelope")
      expect(body).not_to include("<env:Body>")
    end

    it "declares the SOAP namespace without a prefix" do
      expect(builder.to_s).to include('xmlns="http://schemas.xmlsoap.org/soap/envelope/"')
    end
  end

  describe '#body_attributes' do
    it 'is not nil' do
      expect(builder.body_attributes).to eq({})
    end
  end

  describe "#header_attributes" do
    it "declares the wsa prefix when :use_wsa_headers is set" do
      globals[:use_wsa_headers] = true

      expect(builder.header_attributes).to eq(
        "xmlns:wsa" => "http://www.w3.org/2005/08/addressing"
      )
    end

    it "declares nothing otherwise" do
      expect(builder.header_attributes).to eq({})
    end
  end

  describe "WSA_NAMESPACE" do
    # The constant is public since 2.12 and stays available as an alias.
    it "keeps the deprecated alias of the WS-Addressing namespace" do
      expect(described_class::WSA_NAMESPACE).to eq(Savon::Addressing::NAMESPACE)
    end
  end

  describe "namespace declarations" do
    it "includes exactly the required namespaces and no structural namespace declarations" do
      expected = {
        'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:tns' => 'http://v1_0.ws.auth.order.example.com/',
        'xmlns:env' => 'http://schemas.xmlsoap.org/soap/envelope/'
      }
      expect(Nokogiri::XML(builder.to_s).root.namespaces).to match(expected)
    end

    context "with a WSDL that declares multiple namespaces" do
      subject(:multi_builder) { described_class.new(:Save, multi_wsdl, globals, locals) }

      let(:multi_wsdl) { Wasabi::Document.new Fixture.wsdl(:multiple_namespaces) }

      it "includes exactly the required namespaces and no structural namespace declarations" do
        expected = {
          'xmlns:xsd'     => 'http://www.w3.org/2001/XMLSchema',
          'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
          'xmlns:wsdl'    => 'http://example.com/actions',
          'xmlns:env'     => 'http://schemas.xmlsoap.org/soap/envelope/',
          'xmlns:article' => 'http://example.com/article'
        }
        expect(Nokogiri::XML(multi_builder.to_s).root.namespaces).to match(expected)
      end

      it "does not declare the same URI under two different prefixes" do
        uris = multi_builder.to_s.scan(/xmlns:[^=]+="([^"]+)"/).flatten
        expect(uris).to eq(uris.uniq)
      end

      it "does not produce duplicate namespace declarations when :namespaces overlaps with WSDL-derived namespaces" do
        globals[:namespaces] = { "xmlns:article" => "http://example.com/article" }
        xml = multi_builder.to_s
        expect(xml.scan('xmlns:article=').length).to eq(1)
      end

      it "reuses the prefix already declared for a type's namespace URI" do
        locals_with_msg = Savon::LocalOptions.new(message: { article: { Author: "Test", Title: "Article" } })
        xml = described_class.new(:Save, multi_wsdl, globals, locals_with_msg).to_s
        expect(xml).to include("<wsdl:article><article:author>Test</article:author>")
      end

      it "every prefix used in the body is declared in the envelope" do
        locals_with_msg = Savon::LocalOptions.new(message: { article: { Author: "Test", Title: "Article" } })
        builder = described_class.new(:Save, multi_wsdl, globals, locals_with_msg)
        xml = builder.to_s
        used_prefixes     = xml.scan(%r{</?([a-zA-Z][a-zA-Z0-9-]*):}).flatten.uniq
        declared_prefixes = xml.scan(/xmlns:([a-zA-Z][a-zA-Z0-9-]*)=/).flatten.uniq
        expect(used_prefixes).not_to be_empty
        expect(used_prefixes - declared_prefixes).to be_empty
      end
    end

    context "with a schema whose targetNamespace is the WSDL root's default namespace" do
      subject(:default_builder) { described_class.new(:op, default_wsdl, globals, locals_with_msg) }

      let(:default_wsdl)    { Wasabi::Document.new Fixture.wsdl(:default_namespace_target) }
      let(:locals_with_msg) { Savon::LocalOptions.new(message: { a: "1" }) }

      it "falls back to an insN prefix instead of the reserved xmlns prefix" do
        xml = default_builder.to_s
        expect(xml).not_to include("xmlns:xmlns")
        expect(xml).to include('xmlns:ins0="http://schemas.xmlsoap.org/wsdl/"')
        expect(xml).to include("<ins0:a>1</ins0:a>")
      end

      it "produces namespace-well-formed XML" do
        expect(Nokogiri::XML(default_builder.to_s, &:strict).errors).to be_empty
      end

      it "reuses another prefix the WSDL declares for the same URI" do
        wsdl_xml = Fixture.wsdl(:default_namespace_target).sub("xmlns:soap=", 'xmlns:def="http://schemas.xmlsoap.org/wsdl/" xmlns:soap=')
        xml = described_class.new(:op, Wasabi::Document.new(wsdl_xml), globals, locals_with_msg).to_s
        expect(xml).not_to include("xmlns:xmlns")
        expect(xml).to include("<def:a>1</def:a>")
      end
    end
  end

  describe "ordering the message with order!: :use_schema" do
    let(:wsdl) { Wasabi::Document.new Fixture.wsdl(:schema_order) }

    def body_for(message)
      locals = Savon::LocalOptions.new(message: message)
      described_class.new(:place_order, wsdl, globals, locals).to_s[%r{<tns:PlaceOrder>.*</tns:PlaceOrder>}]
    end

    it "orders each level of the message like the schema sequence" do
      message = { total: 9, address: { zip: "75001", street: "1 Main St", city: "Paris" }, customer: "alice", order!: :use_schema }

      expect(body_for(message)).to eq(
        "<tns:PlaceOrder><tns:customer>alice</tns:customer>" \
        "<tns:address><tns:street>1 Main St</tns:street><tns:city>Paris</tns:city><tns:zip>75001</tns:zip></tns:address>" \
        "<tns:total>9</tns:total></tns:PlaceOrder>"
      )
    end

    it "places an optional element given by the caller at its schema position" do
      message = { total: 9, note: "fragile", customer: "alice", order!: :use_schema }

      expect(body_for(message)).to eq(
        "<tns:PlaceOrder><tns:customer>alice</tns:customer><tns:note>fragile</tns:note><tns:total>9</tns:total></tns:PlaceOrder>"
      )
    end

    it "puts keys unknown to the schema last, in the caller's order" do
      message = { gift: true, total: 9, coupon: "XMAS", customer: "alice", order!: :use_schema }

      expect(body_for(message)).to eq(
        "<tns:PlaceOrder><tns:customer>alice</tns:customer><tns:total>9</tns:total>" \
        "<tns:gift>true</tns:gift><tns:coupon>XMAS</tns:coupon></tns:PlaceOrder>"
      )
    end

    it "orders keys whose value Gyoku writes unescaped" do
      message = { total: 9, note!: "<b>fragile</b>", customer: "alice", order!: :use_schema }

      expect(body_for(message)).to eq(
        "<tns:PlaceOrder><tns:customer>alice</tns:customer><tns:note><b>fragile</b></tns:note><tns:total>9</tns:total></tns:PlaceOrder>"
      )
    end

    it "keeps an explicit order! given on a nested hash" do
      message = { address: { zip: "75001", city: "Paris", order!: %i[zip city] }, customer: "alice", order!: :use_schema }

      expect(body_for(message)).to eq(
        "<tns:PlaceOrder><tns:customer>alice</tns:customer>" \
        "<tns:address><tns:zip>75001</tns:zip><tns:city>Paris</tns:city></tns:address></tns:PlaceOrder>"
      )
    end

    it "orders every hash of an array" do
      message = { customer: "alice", address: [{ city: "Paris", street: "1 Main St" }, { city: "Lyon", street: "2 Side St" }], order!: :use_schema }

      expect(body_for(message)).to eq(
        "<tns:PlaceOrder><tns:customer>alice</tns:customer>" \
        "<tns:address><tns:street>1 Main St</tns:street><tns:city>Paris</tns:city></tns:address>" \
        "<tns:address><tns:street>2 Side St</tns:street><tns:city>Lyon</tns:city></tns:address></tns:PlaceOrder>"
      )
    end

    it "leaves the caller's message untouched" do
      message = { total: 9, customer: "alice", order!: :use_schema }

      expect { body_for(message) }.not_to(change { message })
    end

    it "keeps the caller's order without :use_schema" do
      expect(body_for({ total: 9, customer: "alice" })).to eq(
        "<tns:PlaceOrder><tns:total>9</tns:total><tns:customer>alice</tns:customer></tns:PlaceOrder>"
      )
    end
  end
end
