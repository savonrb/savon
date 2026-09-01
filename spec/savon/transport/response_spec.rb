# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::Transport::Response do
  subject(:response) { described_class.new(code, headers, body) }

  let(:code)    { 200 }
  let(:headers) { { "content-type" => "text/xml" } }
  let(:body)    { "<soap:Envelope/>" }

  describe "#code" do
    it "returns the HTTP status code" do
      expect(response.code).to eq(200)
    end
  end

  describe "#headers" do
    it "returns the response headers" do
      expect(response.headers).to eq("content-type" => "text/xml")
    end
  end

  describe "#body" do
    it "returns the response body string" do
      expect(response.body).to eq("<soap:Envelope/>")
    end
  end

  describe "#error?" do
    context "when code is below 300" do
      let(:code) { 299 }

      it "returns false" do
        expect(response.error?).to be(false)
      end
    end

    context "when code is exactly 300" do
      let(:code) { 300 }

      it "returns true" do
        expect(response.error?).to be(true)
      end
    end

    context "when code is above 300" do
      let(:code) { 500 }

      it "returns true" do
        expect(response.error?).to be(true)
      end
    end
  end

  describe "#cookies" do
    it "returns the parsed cookies passed in via the constructor" do
      parsed = %i[any transport shape]
      expect(described_class.new(200, {}, "", cookies: parsed).cookies).to eq(parsed)
    end

    it "defaults to nil when no cookies are supplied" do
      expect(described_class.new(200, {}, "").cookies).to be_nil
    end
  end

  describe ".from_httpi" do
    subject(:response) { described_class.from_httpi(httpi_response) }

    let(:httpi_response) do
      HTTPI::Response.new(201, { "Set-Cookie" => "session=test; Path=/", "x-foo" => "bar" }, "payload")
    end

    it "maps the HTTPI status code onto #code" do
      expect(response.code).to eq(201)
    end

    it "carries the headers and body across unchanged" do
      expect(response.headers).to include("x-foo" => "bar")
      expect(response.body).to eq("payload")
    end

    it "exposes cookies as an Array of HTTPI::Cookie" do
      expect(response.cookies).to all(be_a(HTTPI::Cookie))
      expect(response.cookies.map(&:name_and_value)).to eq(["session=test"])
    end
  end

  describe ".from_faraday" do
    subject(:response) { described_class.from_faraday(faraday_response) }

    let(:faraday_response) do
      env = Faraday::Env.new
      env.status = 201
      env.response_headers = { "Set-Cookie" => "session=test; Path=/", "x-foo" => "bar" }
      env.response_body = "payload"
      Faraday::Response.new(env)
    end

    it "maps the Faraday status onto #code" do
      expect(response.code).to eq(201)
    end

    it "carries the headers and body across unchanged" do
      expect(response.headers).to include("x-foo" => "bar")
      expect(response.body).to eq("payload")
    end

    it "exposes cookies as a Hash of name => value" do
      expect(response.cookies).to eq("session" => "test")
    end
  end
end
