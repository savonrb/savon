# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::HTTPError do
  let(:http_error) { described_class.new new_response(code: 404, body: "Not Found") }
  let(:http_error_with_empty_body) { described_class.new new_response(code: 404, body: "") }
  let(:no_error) { described_class.new new_response }

  it "inherits from Savon::Error" do
    expect(described_class.ancestors).to include(Savon::Error)
  end

  describe ".present?" do
    it "returns true if there was an HTTP error" do
      http = new_response(code: 404, body: "Not Found")
      expect(described_class).to be_present(http)
    end

    it "returns false unless there was an HTTP error" do
      expect(described_class).not_to be_present(new_response)
    end
  end

  describe "#http" do
    it "returns the HTTPI::Response" do
      expect(http_error.http).to be_a(HTTPI::Response)
    end
  end

  %i[message to_s].each do |method|
    describe "##{method}" do
      it "returns the HTTP error message" do
        expect(http_error.send(method)).to eq("HTTP error (404): Not Found")
      end

      context "when the body is empty" do
        it "returns the HTTP error without the body message" do
          expect(http_error_with_empty_body.send(method)).to eq("HTTP error (404)")
        end
      end
    end
  end

  describe "#to_hash" do
    it "returns the HTTP response details as a Hash" do
      expect(http_error.to_hash).to eq(code: 404, headers: {}, body: "Not Found")
    end
  end

  def new_response(options = {})
    defaults = { code: 200, headers: {}, body: Fixture.response(:authentication) }
    response = defaults.merge options

    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end
end
