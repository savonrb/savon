# frozen_string_literal: true

require "spec_helper"
require "logger"
require "stringio"

RSpec.describe Savon::Future do
  let(:no_wsdl_globals) { { endpoint: "http://example.com", namespace: "http://v1.example.com" } }

  describe "validation" do
    it "raises ArgumentError for a non-boolean value" do
      expect { Savon::GlobalOptions.new(future: 1) }
        .to raise_error(ArgumentError, /future: expects true or false/)
    end

    it "defaults to false" do
      expect(Savon::GlobalOptions.new[:future]).to be(false)
    end

    it "is not available as a local option" do
      expect { Savon::LocalOptions.new(future: true) }
        .to raise_error(Savon::UnknownOptionError)
    end
  end

  describe "previewed defaults" do
    it "applies the previewed defaults" do
      globals = Savon::GlobalOptions.new(future: true)

      expect(globals[:transport]).to eq(:faraday)
    end

    it "keeps explicitly set options" do
      globals = Savon::GlobalOptions.new(future: true, transport: :httpi)

      expect(globals[:transport]).to eq(:httpi)
    end

    it "keeps explicitly set options regardless of hash order" do
      globals = Savon::GlobalOptions.new(transport: :httpi, future: true)

      expect(globals[:transport]).to eq(:httpi)
    end

    it "applies the previewed defaults when set after initialization" do
      globals = Savon::GlobalOptions.new
      globals[:future] = true

      expect(globals[:transport]).to eq(:faraday)
    end

    it "applies the previewed defaults when enabled in a client block" do
      client = Savon.client(no_wsdl_globals) { future true }

      expect(client.globals[:transport]).to eq(:faraday)
    end

    it "keeps options set explicitly in a client block" do
      client = Savon.client(no_wsdl_globals) {
        transport :httpi
        future true
      }

      expect(client.globals[:transport]).to eq(:httpi)
    end

    it "rejects HTTPI-only options just like an explicit faraday transport" do
      globals = no_wsdl_globals.merge(future: true, proxy: "http://proxy.example.com")

      expect { Savon.client(globals) }
        .to raise_error(Savon::InitializationError, /proxy/)
    end
  end

  describe "response parsing" do
    let(:response_xml) do
      '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' \
        "<env:Body><authenticateResponse>" \
        '<token attr="x">abc</token><empty/><flag>true</flag>' \
        "</authenticateResponse></env:Body></env:Envelope>"
    end

    def parsed_body(globals_hash = {}, locals_hash = {})
      globals = Savon::GlobalOptions.new({ future: true }.merge(globals_hash))
      locals  = Savon::LocalOptions.new(locals_hash)
      http    = Savon::Transport::Response.new(200, {}, response_xml)

      Savon::Response.new(http, globals, locals).body[:authenticate_response]
    end

    it "maps empty tags to an empty string (nori standards profile)" do
      expect(parsed_body[:empty]).to eq("")
    end

    it "returns text with attributes as a plain hash (nori serializable profile)" do
      expect(parsed_body[:token]).to eq({ "#text": "abc", "@attr": "x" })
    end

    it "does not guess types without a schema (nori standards profile)" do
      expect(parsed_body[:flag]).to eq("true")
    end

    it "keeps an explicit advanced_typecasting option over the profile default" do
      body = parsed_body({}, advanced_typecasting: true)

      expect(body[:flag]).to be(true)
    end

    it "keeps an explicit empty_tag_value option over the profile default" do
      body = parsed_body(empty_tag_value: nil)

      expect(body[:empty]).to be_nil
    end

    it "leaves parsing untouched without the flag" do
      body = parsed_body(future: false)

      expect(body[:empty]).to be_nil
      expect(body[:token]).to eq("abc")
      expect(body[:flag]).to be(true)
    end
  end

  describe "frozen options" do
    it "freezes the globals once the client is created" do
      client = Savon.client(no_wsdl_globals.merge(future: true))

      expect(client.globals).to be_frozen
    end

    it "raises a helpful error when setting a global after client creation" do
      client = Savon.client(no_wsdl_globals.merge(future: true))

      expect { client.globals[:log] = true }
        .to raise_error(FrozenError, /frozen once the client is created/)
    end

    it "keeps resolving reads on the frozen globals" do
      client = Savon.client(no_wsdl_globals.merge(future: true))

      # :soap_version comes from the defaults layer - reading it must not
      # write any memoization state to the frozen object.
      expect(client.globals[:soap_version]).to eq(1)
    end

    it "keeps the globals mutable without the flag" do
      client = Savon.client(no_wsdl_globals)
      client.globals[:log] = true

      expect(client.globals[:log]).to be(true)
    end
  end

  describe "the preview announcement" do
    def client_output(globals = {})
      io = StringIO.new
      Savon.client(no_wsdl_globals.merge(logger: Logger.new(io)).merge(globals))
      io.string
    end

    it "logs one info line at client initialization" do
      output = client_output(future: true)

      expect(output).to include("future: true")
      expect(output).to include("https://github.com/savonrb/savon/discussions/1060")
    end

    it "logs nothing when the flag is off" do
      expect(client_output).to be_empty
    end

    it "is silenced by a log_level above info" do
      expect(client_output(future: true, log_level: :warn)).to be_empty
    end
  end
end
