# frozen_string_literal: true
require "spec_helper"
require "faraday/adapter/test"
require "savon/transport/faraday"

RSpec.describe Savon::Transport::Faraday do
  let(:stubs)   { ::Faraday::Adapter::Test::Stubs.new }
  let(:globals) { Savon::GlobalOptions.new(:log => false) }
  let(:connection) do
    ::Faraday.new do |f|
      f.adapter :test, stubs
    end
  end

  subject(:transport) { described_class.new(connection, globals) }

  let(:url)    { "http://example.com/soap" }
  let(:body)   { "<soap:Envelope/>" }
  let(:locals) { Savon::LocalOptions.new }

  describe "#post" do
    it "returns a Transport::Response" do
      stubs.post("/soap") { [200, {}, "<response/>"] }
      expect(transport.post(url, {}, body, locals)).to be_a(Savon::Transport::Response)
    end

    it "forwards all soap_headers to the HTTP request" do
      captured = nil
      stubs.post("/soap") { |env|
        captured = env.request_headers
        [200, {}, "ok"]
      }
      transport.post(url, { "SOAPAction" => '"test-op"', "Content-Type" => "text/xml;charset=UTF-8" }, body, locals)
      expect(captured["SOAPAction"]).to    eq('"test-op"')
      expect(captured["Content-Type"]).to  eq("text/xml;charset=UTF-8")
    end

    it "preserves the code, headers, and body from the HTTP response" do
      stubs.post("/soap") { [201, { "x-foo" => "bar" }, "payload"] }
      result = transport.post(url, {}, body, locals)
      expect(result.code).to eq(201)
      expect(result.headers).to include("x-foo" => "bar")
      expect(result.body).to eq("payload")
    end

    it "includes soap_headers in the request" do
      captured = nil
      stubs.post("/soap") { |env|
        captured = env
        [200, {}, "ok"]
      }
      transport.post(url, { "Content-Type" => "text/xml;charset=UTF-8" }, body, locals)
      expect(captured.request_headers["Content-Type"]).to eq("text/xml;charset=UTF-8")
    end

    it "includes globals[:headers]" do
      globals.headers("X-Token" => "secret")
      captured = nil
      stubs.post("/soap") { |env|
        captured = env
        [200, {}, "ok"]
      }
      transport.post(url, {}, body, locals)
      expect(captured.request_headers["X-Token"]).to eq("secret")
    end

    it "globals[:headers] take precedence over soap_headers for the same key" do
      globals.headers("SOAPAction" => '"from-globals"')
      captured = nil
      stubs.post("/soap") { |env|
        captured = env
        [200, {}, "ok"]
      }
      transport.post(url, { "SOAPAction" => '"from-soap"' }, body, locals)
      expect(captured.request_headers["SOAPAction"]).to eq('"from-globals"')
    end

    it "includes locals[:headers]" do
      locals_with_headers = Savon::LocalOptions.new(headers: { "X-Request-Id" => "abc" })
      captured = nil
      stubs.post("/soap") { |env|
        captured = env
        [200, {}, "ok"]
      }
      transport.post(url, {}, body, locals_with_headers)
      expect(captured.request_headers["X-Request-Id"]).to eq("abc")
    end

    it "locals[:headers] take precedence over globals[:headers]" do
      globals.headers("X-Custom" => "from-globals")
      locals_with_headers = Savon::LocalOptions.new(headers: { "X-Custom" => "from-locals" })
      captured = nil
      stubs.post("/soap") { |env|
        captured = env
        [200, {}, "ok"]
      }
      transport.post(url, {}, body, locals_with_headers)
      expect(captured.request_headers["X-Custom"]).to eq("from-locals")
    end

    it "locals[:headers] take precedence over soap_headers for the same key" do
      locals_with_headers = Savon::LocalOptions.new(headers: { "SOAPAction" => '"from-locals"' })
      captured = nil
      stubs.post("/soap") { |env|
        captured = env
        [200, {}, "ok"]
      }
      transport.post(url, { "SOAPAction" => '"from-soap"' }, body, locals_with_headers)
      expect(captured.request_headers["SOAPAction"]).to eq('"from-locals"')
    end

    it "converts cookies to a Cookie: header" do
      cookies = [HTTPI::Cookie.new("session=abc"), HTTPI::Cookie.new("user=dan")]
      locals_with_cookies = Savon::LocalOptions.new(cookies: cookies)
      captured = nil
      stubs.post("/soap") { |env|
        captured = env
        [200, {}, "ok"]
      }
      transport.post(url, {}, body, locals_with_cookies)
      expect(captured.request_headers["Cookie"]).to eq("session=abc;user=dan")
    end

    it "computes Content-Length from the body byte size" do
      body_str = "hello"
      captured = nil
      stubs.post("/soap") { |env|
        captured = env
        [200, {}, "ok"]
      }
      transport.post(url, {}, body_str, locals)
      expect(captured.request_headers["Content-Length"]).to eq(body_str.bytesize.to_s)
    end

    it "skips LogMessage construction when the logger level would suppress the output" do
      globals_logging = Savon::GlobalOptions.new(:log => true)
      globals_logging[:logger].level = Logger::FATAL
      logging_stubs = ::Faraday::Adapter::Test::Stubs.new
      logging_stubs.post("/soap") { [200, {}, "ok"] }
      logging_conn = ::Faraday.new { |f| f.adapter :test, logging_stubs }

      Savon::LogMessage.expects(:new).never
      described_class.new(logging_conn, globals_logging).post(url, {}, body, locals)
    end
  end
end
