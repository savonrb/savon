# frozen_string_literal: true
require "spec_helper"

RSpec.describe Savon::HTTPError do
  let(:http_error) { Savon::HTTPError.new new_response(:code => 404, :body => "Not Found") }
  let(:http_error_with_empty_body) { Savon::HTTPError.new new_response(:code => 404, :body => "") }
  let(:no_error) { Savon::HTTPError.new new_response }

  it "inherits from Savon::Error" do
    expect(Savon::HTTPError.ancestors).to include(Savon::Error)
  end

  describe ".present?" do
    it "returns true if there was an HTTP error" do
      http = new_response(:code => 404, :body => "Not Found")
      expect(Savon::HTTPError.present? http).to be_truthy
    end

    it "returns false unless there was an HTTP error" do
      expect(Savon::HTTPError.present? new_response).to be_falsey
    end
  end

  describe "#http" do
    it "returns the HTTPI::Response" do
      expect(http_error.http).to be_a(Faraday::Response)
    end
  end

  [:message, :to_s].each do |method|
    describe "##{method}" do
      it "returns the HTTP error message" do
        expect(http_error.send method).to eq("HTTP error (404): Not Found")
      end

      context "when the body is empty" do
        it "returns the HTTP error without the body message" do
          expect(http_error_with_empty_body.send method).to eq("HTTP error (404)")
        end
      end
    end
  end

  describe "#to_hash" do
    it "returns the HTTP response details as a Hash" do
      expect(http_error.to_hash).to eq(:code => 404, :headers => {}, :body => "Not Found")
    end
  end

  def new_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    env = Faraday::Env.new(status: response[:code], response_headers: response[:headers], response_body: response[:body])
    Faraday::Response.new(env)
  end

end
