# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"
require "json"

# Integration tests for the cookies round-trip on both transports.
# Verifies:
#   * response.http.cookies is populated from Set-Cookie headers
#   * The shape of cookies is transport-specific (HTTPI::Cookie array vs Hash)
#   * client.call(cookies: previous_response.http.cookies) works on both
RSpec.describe "Cookie round-trip across transports" do
  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  def build_client(transport)
    Savon.client(
      endpoint: @server.url(:cookies_roundtrip),
      namespace: "http://v1.example.com",
      transport: transport,
      log: false
    )
  end

  def echoed_cookie_header(response)
    JSON.parse(response.http.body).fetch("cookie")
  end

  describe "HTTPI transport" do
    let(:client) { build_client(:httpi) }

    it "exposes response.http.cookies as an Array of HTTPI::Cookie" do
      response = client.call(:authenticate)
      cookies = response.http.cookies

      expect(cookies).to all(be_a(HTTPI::Cookie))
      expect(cookies.map(&:name_and_value)).to eq(%w[session=abc user=dan])
    end

    it "round-trips cookies via response.http.cookies" do
      first  = client.call(:authenticate)
      second = client.call(:authenticate, cookies: first.http.cookies)

      cookie_header = echoed_cookie_header(second)
      expect(cookie_header.split(";").map(&:strip)).to contain_exactly("session=abc", "user=dan")
    end
  end

  describe "Faraday transport" do
    let(:client) { build_client(:faraday) }

    it "exposes response.http.cookies as a Hash of name => value" do
      response = client.call(:authenticate)
      expect(response.http.cookies).to eq("session" => "abc", "user" => "dan")
    end

    it "round-trips cookies via response.http.cookies" do
      first  = client.call(:authenticate)
      second = client.call(:authenticate, cookies: first.http.cookies)

      cookie_header = echoed_cookie_header(second)
      expect(cookie_header.split("; ")).to contain_exactly("session=abc", "user=dan")
    end
  end
end
