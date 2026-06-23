# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"

# Integration coverage for the WSDL-fetch failure path.
#
# When a WSDL document cannot be fetched, Wasabi raises a
# Wasabi::Resolver::HTTPError and we wrap that in a Savon::HTTPError.
RSpec.describe "WSDL fetch failure" do
  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  describe "over the HTTPI transport" do
    let(:error) { http_error_for(:httpi) }

    it "raises a Savon::HTTPError" do
      expect(error).to be_a(Savon::HTTPError)
    end

    it "renders the status and body via #to_s" do
      expect(error.to_s).to eq("HTTP error (502): Bad Gateway")
    end

    it "renders the status and body via #to_hash" do
      expect(error.to_hash).to eq(code: 502, headers: error.http.headers, body: "Bad Gateway")
    end
  end

  describe "over the Faraday transport" do
    let(:error) { http_error_for(:faraday) }

    it "raises a Savon::HTTPError" do
      expect(error).to be_a(Savon::HTTPError)
    end

    it "renders the status and body via #to_s" do
      expect(error.to_s).to eq("HTTP error (502): Bad Gateway")
    end

    it "renders the status and body via #to_hash" do
      expect(error.to_hash).to eq(code: 502, headers: error.http.headers, body: "Bad Gateway")
    end
  end

  # Captures the Savon::HTTPError raised when resolving an
  # operation against a WSDL URL that responds with 502.
  def http_error_for(transport)
    client = Savon.client(
      wsdl: @server.url("server_error"),
      transport: transport,
      log: false
    )

    client.call(:any_operation)
    nil
  rescue Savon::HTTPError => e
    e
  end
end
