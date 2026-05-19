# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::Transport::Response do
  let(:code)    { 200 }
  let(:headers) { { "content-type" => "text/xml" } }
  let(:body)    { "<soap:Envelope/>" }

  subject(:response) { described_class.new(code, headers, body) }

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

  describe ".from_faraday" do
    it "wraps a Faraday::Response, preserving status, headers, and body" do
      faraday = stub(status: 201, headers: { "x-custom" => "val" }, body: "payload")
      result  = described_class.from_faraday(faraday)

      expect(result).to be_a(described_class)
      expect(result.code).to eq(201)
      expect(result.headers).to eq("x-custom" => "val")
      expect(result.body).to eq("payload")
    end

    it "preserves error? semantics from the Faraday response status" do
      faraday_ok  = stub(status: 200, headers: {}, body: "ok")
      faraday_err = stub(status: 503, headers: {}, body: "error")

      expect(described_class.from_faraday(faraday_ok).error?).to be(false)
      expect(described_class.from_faraday(faraday_err).error?).to be(true)
    end
  end

  describe ".from_httpi" do
    it "wraps an HTTPI::Response, preserving code, headers, and body" do
      httpi = HTTPI::Response.new(201, { "x-custom" => "val" }, "payload")
      result = described_class.from_httpi(httpi)

      expect(result).to be_a(described_class)
      expect(result.code).to eq(201)
      expect(result.headers).to eq("x-custom" => "val")
      expect(result.body).to eq("payload")
    end

    it "preserves error? semantics from the HTTPI response code" do
      httpi_ok  = HTTPI::Response.new(200, {}, "ok")
      httpi_err = HTTPI::Response.new(503, {}, "error")

      expect(described_class.from_httpi(httpi_ok).error?).to be(false)
      expect(described_class.from_httpi(httpi_err).error?).to be(true)
    end
  end
end
