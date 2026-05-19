# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"
require "json"
require "ostruct"

# Integration tests for the opt-in Faraday transport.
# Each test makes a real HTTP request to the local Puma/Rack test server.
RSpec.describe "Savon client with transport: :faraday" do
  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  def new_client(extra = {})
    Savon.client(
      { endpoint: @server.url(:repeat),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false }.merge(extra)
    )
  end

  def inspect_request(response)
    OpenStruct.new JSON.parse(response.http.body)
  end

  it "routes a SOAP call through the Faraday transport and returns a Savon::Response" do
    response = new_client.call(:authenticate, message: { symbol: "AAPL" })
    expect(response).to        be_a(Savon::Response)
    expect(response.http).to   be_a(Savon::Transport::Response)
    expect(response.http.body).to include("<symbol>AAPL</symbol>")
  end

  it "applies a default header set on client.faraday to the outbound request" do
    client = Savon.client(
      endpoint: @server.url(:inspect_request),
      namespace: "http://v1.example.com",
      transport: :faraday,
      log: false
    )
    client.faraday.headers["X-Token"] = "from-faraday"

    data = inspect_request(client.call(:authenticate))
    expect(data.x_token).to eq("from-faraday")
  end

  it "fetches a remote WSDL through the Faraday connection" do
    client = Savon.client(
      wsdl: @server.url("authentication.wsdl"),
      transport: :faraday,
      log: false
    )
    expect(client.operations).to include(:authenticate)
  end

  it "sends a multipart request and parses a multipart response" do
    client = Savon.client(
      endpoint: @server.url(:multipart),
      namespace: "http://v1.example.com",
      transport: :faraday,
      log: false
    )
    response = client.call(:authenticate) {
      attachments [{ filename: "x1.xml", content: "<xml>abc</xml>" }]
    }

    expect(response.multipart?).to be true
  end

  it "forwards cookies as the Cookie: header" do
    client = Savon.client(
      endpoint: @server.url(:inspect_request),
      namespace: "http://v1.example.com",
      transport: :faraday,
      log: false
    )
    response = client.call(:authenticate, cookies: [HTTPI::Cookie.new("session=abc")])
    expect(inspect_request(response).cookie).to include("session=abc")
  end

  it "sends the exact Content-Length on the wire (via the Faraday adapter)" do
    client = Savon.client(
      endpoint: @server.url(:inspect_request),
      namespace: "http://v1.example.com",
      transport: :faraday,
      log: false
    )
    data = inspect_request(client.call(:authenticate))
    expect(data.content_length).to match(/\A\d+\z/), "expected a single integer - a comma would mean the header was sent twice"
    expect(data.content_length).to eq(data.body_bytesize)
  end
end
