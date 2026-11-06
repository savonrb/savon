# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"
require "faraday/adapter/test"
require "json"
require "ostruct"

# Security regression tests for GHSA-57m8-w3r7-5p3w.
#
# A crafted WSDL (or crafted caller input) can push CR, LF, or NUL into the outbound SOAPAction header.
# With some HTTP adapters the header splits on the wire and extra request headers are injected.
# The resolved SOAPAction is validated at the transport layer, so every send path for both transports
# rejects the value before it reaches the network.
RSpec.describe "SOAPAction header injection" do
  def inspect_request(response)
    OpenStruct.new JSON.parse(response.http.body)
  end

  injection_message = /illegal control characters \(CR, LF, or NUL\)/

  describe "the default (HTTPI) transport" do
    context "when the WSDL soapAction carries CR/LF character references" do
      let(:client) { Savon.client(wsdl: Fixture.wsdl(:crlf_injection), log: false) }

      # The fixture encodes the split as &#13;&#10;,
      # which survives XML attribute normalization and reaches the header as a real CRLF.
      it "raises Savon::InvalidHeaderError on #call" do
        expect { client.call(:authenticate, message: { user: "dan" }) }
          .to raise_error(Savon::InvalidHeaderError, injection_message)
      end

      it "raises Savon::InvalidHeaderError on #request" do
        expect { client.build_request(:authenticate, message: { user: "dan" }) }
          .to raise_error(Savon::InvalidHeaderError, injection_message)
      end

      it "names the offending value in the message" do
        expect { client.call(:authenticate, message: { user: "dan" }) }
          .to raise_error(Savon::InvalidHeaderError, /urn:legit/)
      end

      # A caller who overrides SOAPAction with a clean value wins the header merge,
      # so the crafted WSDL value is never sent. Validation runs on the resolved header,
      # so this must not false-raise.
      it "does not raise when a clean caller SOAPAction overrides the WSDL value" do
        expect {
          client.build_request(
            :authenticate,
            message: { user: "dan" },
            headers: { "SOAPAction" => %("urn:clean") }
          )
        }.not_to raise_error
      end
    end

    context "without a WSDL" do
      let(:client) do
        Savon.client(
          endpoint: integration_server.url(:inspect_request),
          namespace: "http://v1.example.com",
          log: false
        )
      end

      it "raises for a :soap_action option with interior CR/LF" do
        expect { client.call(:authenticate, soap_action: "urn:legit\r\nX-Injected: evil") }
          .to raise_error(Savon::InvalidHeaderError, injection_message)
      end

      # A trailing newline is rejected too. SOAPAction is validated for any control character,
      # not only an interior split.
      it "raises for a :soap_action option with only a trailing newline" do
        expect { client.call(:authenticate, soap_action: "urn:action\n") }
          .to raise_error(Savon::InvalidHeaderError, injection_message)
      end

      it "raises for a caller-supplied SOAPAction header with CR/LF" do
        expect { client.call(:authenticate, headers: { "SOAPAction" => "x\r\ny" }) }
          .to raise_error(Savon::InvalidHeaderError, injection_message)
      end

      # A Symbol key sits next to the default String key,
      # and the httpclient adapter sends both headers.
      it "raises for a caller-supplied Symbol SOAPAction key with CR/LF" do
        expect { client.call(:authenticate, headers: { SOAPAction: "x\r\ny" }) }
          .to raise_error(Savon::InvalidHeaderError, injection_message)
      end

      it "sends a clean SOAPAction without raising" do
        response = nil
        expect { response = client.call(:authenticate, soap_action: "urn:clean-action") }
          .not_to raise_error
        expect(inspect_request(response).soap_action).to eq(%("urn:clean-action"))
      end

      it "sends no SOAPAction header when :soap_action is false, without raising" do
        response = nil
        expect { response = client.call(:authenticate, soap_action: false) }
          .not_to raise_error
        expect(inspect_request(response).soap_action).to be_nil
      end
    end
  end

  describe "the Faraday transport" do
    let(:stubs)      { ::Faraday::Adapter::Test::Stubs.new }
    let(:connection) { ::Faraday.new { |f| f.adapter :test, stubs } }
    let(:transport)  { Savon::Transport::Faraday.new(connection, globals) }
    let(:wsdl) do
      Wasabi::Document.new.tap do |doc|
        doc.endpoint  = "http://example.com/soap"
        doc.namespace = "http://v1.example.com"
      end
    end
    let(:globals) do
      Savon::GlobalOptions.new(
        endpoint: "http://example.com/soap",
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
    end
    let(:operation) { Savon::Operation.create(:authenticate, wsdl, globals, transport) }

    context "when the WSDL soapAction carries CR/LF character references" do
      let(:client) { Savon.client(wsdl: Fixture.wsdl(:crlf_injection), transport: :faraday, log: false) }

      it "raises Savon::InvalidHeaderError on #call" do
        expect { client.call(:authenticate, message: { user: "dan" }) }
          .to raise_error(Savon::InvalidHeaderError, injection_message)
      end
    end

    it "raises for a :soap_action option with interior CR/LF" do
      expect { operation.call(soap_action: "urn:legit\r\nX-Injected: evil") }
        .to raise_error(Savon::InvalidHeaderError, injection_message)
    end

    it "raises for a :soap_action option with only a trailing newline" do
      expect { operation.call(soap_action: "urn:action\n") }
        .to raise_error(Savon::InvalidHeaderError, injection_message)
    end

    it "raises for a caller-supplied SOAPAction header with CR/LF" do
      expect { operation.call(headers: { "SOAPAction" => "x\r\ny" }) }
        .to raise_error(Savon::InvalidHeaderError, injection_message)
    end

    it "sends a clean SOAPAction without raising" do
      captured = nil
      stubs.post("/soap") do |env|
        captured = env.request_headers
        [200, {}, Fixture.response(:authentication)]
      end

      expect { operation.call(soap_action: "urn:clean-action") }.not_to raise_error
      expect(captured["SOAPAction"]).to eq(%("urn:clean-action"))
    end

    it "sends no SOAPAction header when :soap_action is false, without raising" do
      captured = nil
      stubs.post("/soap") do |env|
        captured = env.request_headers
        [200, {}, Fixture.response(:authentication)]
      end

      expect { operation.call(soap_action: false) }.not_to raise_error
      expect(captured["SOAPAction"]).to be_nil
    end
  end
end
