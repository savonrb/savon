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
end
