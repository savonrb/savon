# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::EffectiveOptions do
  subject(:effective) { described_class.new(operation_name, wsdl, globals, locals) }

  let(:operation_name) { :verify_address }
  let(:wsdl)           { Wasabi::Document.new Fixture.wsdl(:taxcloud) }
  let(:globals)        { Savon::GlobalOptions.new }
  let(:locals)         { Savon::LocalOptions.new }

  describe "#wsse_auth" do
    it "prefers the local credentials over the global ones" do
      globals[:wsse_auth] = %w[global_user global_pass]
      locals[:wsse_auth]  = %w[local_user local_pass]

      expect(effective.wsse_auth).to eq(%w[local_user local_pass])
    end

    it "keeps the global credentials when the local option is unset" do
      globals[:wsse_auth] = %w[global_user global_pass]

      expect(effective.wsse_auth).to eq(%w[global_user global_pass])
    end

    it "lets a local false disable the global credentials" do
      globals[:wsse_auth] = %w[global_user global_pass]
      locals[:wsse_auth]  = false

      expect(effective.wsse_auth).to be(false)
    end
  end

  describe "#wsse_timestamp" do
    it "prefers the local value over the global one" do
      globals[:wsse_timestamp] = true
      locals[:wsse_timestamp]  = false

      expect(effective.wsse_timestamp).to be(false)
    end

    it "keeps the global value when the local option is unset" do
      globals[:wsse_timestamp] = true

      expect(effective.wsse_timestamp).to be(true)
    end
  end

  describe "#wsse_signature" do
    it "prefers the local signature over the global one" do
      globals[:wsse_signature] = :global_signature
      locals[:wsse_signature]  = :local_signature

      expect(effective.wsse_signature).to eq(:local_signature)
    end

    it "falls back to the global signature when the local option is unset" do
      globals[:wsse_signature] = :global_signature

      expect(effective.wsse_signature).to eq(:global_signature)
    end

    # Unlike wsse_auth/wsse_timestamp, the signature has no "disable" value, so a
    # falsy local value falls back to the global one rather than disabling it.
    it "falls back to the global signature when the local option is false" do
      globals[:wsse_signature] = :global_signature
      locals[:wsse_signature]  = false

      expect(effective.wsse_signature).to eq(:global_signature)
    end
  end

  describe "#soap_header" do
    it "merges the two headers when both are Hashes, with local winning per key" do
      globals[:soap_header] = { global_only: 1, shared: :from_global }
      locals[:soap_header]  = { local_only: 2, shared: :from_local }

      expect(effective.soap_header).to eq(
        global_only: 1, local_only: 2, shared: :from_local
      )
    end

    it "prefers the local header when they are not both Hashes" do
      globals[:soap_header] = { global_only: 1 }
      locals[:soap_header]  = "<custom/>"

      expect(effective.soap_header).to eq("<custom/>")
    end

    it "falls back to the global header when the local option is unset" do
      globals[:soap_header] = { global_only: 1 }

      expect(effective.soap_header).to eq(global_only: 1)
    end
  end

  describe "#soap_action" do
    it "prefers the local :soap_action over the WSDL value" do
      locals[:soap_action] = "http://example.com/explicit"

      expect(effective.soap_action).to eq("http://example.com/explicit")
    end

    it "reads the soapAction of the operation from the WSDL" do
      expect(effective.soap_action).to eq("http://taxcloud.net/VerifyAddress")
    end

    # The WSDL provides a soapAction for this operation, so nil proves the
    # local false disables the action instead of falling through.
    it "returns nil when the local :soap_action is false" do
      locals[:soap_action] = false

      expect(effective.soap_action).to be_nil
    end

    it "falls back to an XML tag built from the operation name without a WSDL" do
      effective = described_class.new(:authenticate, Wasabi::Document.new, globals, locals)

      expect(effective.soap_action).to eq("authenticate")
    end
  end

  describe "#endpoint" do
    it "prefers the global :endpoint over the WSDL value" do
      globals[:endpoint] = "http://example.com/override"

      expect(effective.endpoint).to eq("http://example.com/override")
    end

    it "reads the service endpoint from the WSDL" do
      expect(effective.endpoint.to_s).to eq("https://api.taxcloud.net/1.0/TaxCloud.asmx")
    end

    context "with a global :host override" do
      before do
        globals[:host] = "http://localhost:8080"
      end

      it "replaces host and port and keeps scheme and path" do
        expect(effective.endpoint.to_s).to eq("https://localhost:8080/1.0/TaxCloud.asmx")
      end

      it "does not mutate the WSDL document's endpoint" do
        effective.endpoint

        expect(wsdl.endpoint.to_s).to eq("https://api.taxcloud.net/1.0/TaxCloud.asmx")
      end

      it "resolves to an equal value on every call" do
        first  = effective.endpoint
        second = effective.endpoint

        expect(second).to eq(first)
      end
    end
  end

  # Resolution is a pure read. The readers never write resolved values back
  # into the options they resolve from and never modify the WSDL document.
  describe "resolution invariants" do
    it "does not mutate the global or local options" do
      globals[:soap_header]    = { global_only: 1, shared: :from_global }
      locals[:soap_header]     = { local_only: 2, shared: :from_local }
      globals[:wsse_auth]      = %w[global_user global_pass]
      locals[:wsse_auth]       = false
      globals[:wsse_signature] = :global_signature
      locals[:wsse_signature]  = false

      effective.wsse_auth
      effective.wsse_timestamp
      effective.wsse_signature
      effective.soap_header

      expect(globals[:soap_header]).to eq(global_only: 1, shared: :from_global)
      expect(locals[:soap_header]).to eq(local_only: 2, shared: :from_local)
      expect(globals[:wsse_auth]).to eq(%w[global_user global_pass])
      expect(locals[:wsse_auth]).to be(false)
      expect(locals[:wsse_signature]).to be(false)
    end

    it "does not write resolved values back into the options" do
      effective.soap_action
      effective.endpoint

      expect(locals.include?(:soap_action)).to be(false)
      expect(globals.include?(:endpoint)).to be(false)
    end
  end
end
