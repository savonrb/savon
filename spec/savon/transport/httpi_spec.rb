# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::Transport::HTTPI do
  subject(:transport) { described_class.new(globals) }

  let(:globals) { Savon::GlobalOptions.new(:log => false) }

  describe "#to_httpi_request" do
    let(:url)    { "http://example.com/soap" }
    let(:body)   { "<soap:Envelope/>" }
    let(:locals) { Savon::LocalOptions.new }

    it "returns an HTTPI::Request" do
      expect(transport.to_httpi_request(url, {}, body, locals)).to be_a(HTTPI::Request)
    end

    it "sets the URL" do
      expect(transport.to_httpi_request(url, {}, body, locals).url.to_s).to eq(url)
    end

    it "sets the body" do
      expect(transport.to_httpi_request(url, {}, body, locals).body).to eq(body)
    end

    it "includes soap_headers in the request headers" do
      soap_headers = { "Content-Type" => "text/xml;charset=UTF-8" }
      expect(transport.to_httpi_request(url, soap_headers, body, locals).headers["Content-Type"]).to eq("text/xml;charset=UTF-8")
    end

    it "includes globals[:headers]" do
      globals.headers("X-Token" => "secret")
      expect(transport.to_httpi_request(url, {}, body, locals).headers["X-Token"]).to eq("secret")
    end

    it "globals[:headers] take precedence over soap_headers for the same key" do
      globals.headers("SOAPAction" => '"from-globals"')
      soap_headers = { "SOAPAction" => '"from-soap"' }
      expect(transport.to_httpi_request(url, soap_headers, body, locals).headers["SOAPAction"]).to eq('"from-globals"')
    end

    it "includes locals[:headers]" do
      locals_with_headers = Savon::LocalOptions.new(headers: { "X-Request-Id" => "abc" })
      expect(transport.to_httpi_request(url, {}, body, locals_with_headers).headers["X-Request-Id"]).to eq("abc")
    end

    it "locals[:headers] take precedence over globals[:headers]" do
      globals.headers("X-Custom" => "from-globals")
      locals_with_headers = Savon::LocalOptions.new(headers: { "X-Custom" => "from-locals" })
      expect(transport.to_httpi_request(url, {}, body, locals_with_headers).headers["X-Custom"]).to eq("from-locals")
    end

    it "locals[:headers] take precedence over soap_headers for the same key" do
      locals_with_headers = Savon::LocalOptions.new(headers: { "SOAPAction" => '"from-locals"' })
      soap_headers = { "SOAPAction" => '"from-soap"' }
      expect(transport.to_httpi_request(url, soap_headers, body, locals_with_headers).headers["SOAPAction"]).to eq('"from-locals"')
    end

    it "converts cookies to a Cookie: header" do
      cookies = [HTTPI::Cookie.new("session=abc"), HTTPI::Cookie.new("user=dan")]
      locals_with_cookies = Savon::LocalOptions.new(cookies: cookies)
      expect(transport.to_httpi_request(url, {}, body, locals_with_cookies).headers["Cookie"]).to eq("session=abc;user=dan")
    end

    it "computes Content-Length from the body byte size" do
      body_str = "hello"
      expect(transport.to_httpi_request(url, {}, body_str, locals).headers["Content-Length"]).to eq(body_str.bytesize.to_s)
    end
  end

  describe "#post" do
    let(:url)    { "http://example.com" }
    let(:body)   { "<body/>" }
    let(:locals) { Savon::LocalOptions.new }

    before { HTTPI.stubs(:post).returns(HTTPI::Response.new(200, {}, "ok")) }

    it "returns a Transport::Response" do
      expect(transport.post(url, {}, body, locals)).to be_a(Savon::Transport::Response)
    end

    it "forwards all soap_headers to the HTTP request" do
      captured = nil
      # Mocha stubs are matched LIFO; this overrides the before-block stub for this call.
      HTTPI.stubs(:post).with { |req|
        captured = req.headers
        true
      }.returns(HTTPI::Response.new(200, {}, "ok"))
      transport.post(url, { "SOAPAction" => '"test-op"', "Content-Type" => "text/xml;charset=UTF-8" }, body, locals)
      expect(captured["SOAPAction"]).to    eq('"test-op"')
      expect(captured["Content-Type"]).to  eq("text/xml;charset=UTF-8")
    end

    it "preserves the code, headers, and body from the HTTP response" do
      HTTPI.stubs(:post).returns(HTTPI::Response.new(201, { "x-foo" => "bar" }, "payload"))
      result = transport.post(url, {}, body, locals)
      expect(result.code).to eq(201)
      expect(result.headers).to eq("x-foo" => "bar")
      expect(result.body).to eq("payload")
    end

    it "skips LogMessage construction when the logger level would suppress the output" do
      globals_logging = Savon::GlobalOptions.new(:log => true)
      globals_logging[:logger].level = Logger::FATAL

      Savon::LogMessage.expects(:new).never
      described_class.new(globals_logging).post(url, {}, body, locals)
    end
  end

  describe "#wsdl_request" do
    it "returns an HTTPI::Request" do
      expect(transport.wsdl_request).to be_an(HTTPI::Request)
    end

    it "applies globals[:headers]" do
      globals.headers("X-Api-Key" => "token")
      expect(transport.wsdl_request.headers["X-Api-Key"]).to eq("token")
    end

    it "applies globals[:proxy]" do
      globals.proxy("http://proxy.example.com")
      expect(transport.wsdl_request.proxy.to_s).to eq("http://proxy.example.com")
    end

    it "does not set a proxy when not configured" do
      expect(transport.wsdl_request.proxy).to be_nil
    end

    it "applies globals[:ssl_verify_mode]" do
      globals.ssl_verify_mode(:none)
      expect(transport.wsdl_request.auth.ssl.verify_mode).to eq(:none)
    end

    it "applies globals[:basic_auth]" do
      globals.basic_auth("user", "pass")
      expect(transport.wsdl_request.auth.basic).to eq(%w[user pass])
    end
  end
end
