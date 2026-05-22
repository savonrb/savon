# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"
require "fileutils"
require "openssl"
require "socket"
require "tmpdir"
require "timeout"
require "webrick"
require "webrick/httpproxy"
require "puma/minissl"
require "faraday/follow_redirects"
require "faraday/digestauth"
require "faraday/ntlm_auth"

class FaradayTransportOptionServers
  attr_reader :host, :http_server, :https_server, :mtls_server, :ca_path,
              :proxy_requests, :proxy_port

  def self.start
    new.tap(&:start)
  end

  def initialize
    @host = "127.0.0.1"
    @proxy_requests = []
  end

  def start
    @http_server  = IntegrationServer.run(host: host, port: 0)
    @https_server = IntegrationServer.run(host: host, port: 0, ssl: true)
    @mtls_server  = IntegrationServer.run(
      host: host,
      port: 0,
      ssl: true,
      ssl_ca_file: IntegrationServer.ssl_ca_file,
      ssl_verify_mode: Puma::MiniSSL::VERIFY_PEER | Puma::MiniSSL::VERIFY_FAIL_IF_NO_PEER_CERT
    )
    @ca_path = build_ca_path
    start_proxy
  end

  def stop
    http_server&.stop
    https_server&.stop
    mtls_server&.stop
    FileUtils.rm_rf(ca_path)
    proxy&.shutdown
    proxy_thread&.join(1)
  end

  def proxy_url
    "http://#{host}:#{proxy_port}"
  end

  private

  attr_reader :proxy, :proxy_thread

  def build_ca_path
    Dir.mktmpdir("savon_ca_path_test").tap do |path|
      ca_file = IntegrationServer.ssl_ca_file
      hash = format("%08x", OpenSSL::X509::Certificate.new(File.read(ca_file)).subject.hash)
      FileUtils.cp(ca_file, File.join(path, "#{hash}.0"))
    end
  end

  def start_proxy
    @proxy = WEBrick::HTTPProxyServer.new(
      BindAddress: host,
      Port: 0,
      AccessLog: [],
      Logger: WEBrick::Log.new(IO::NULL),
      RequestCallback: proc { |req, _res| proxy_requests << req.request_uri.to_s }
    )
    @proxy_port = proxy[:Port]
    @proxy_thread = Thread.new { proxy.start }
    wait_for_proxy
  end

  def wait_for_proxy
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5

    loop do
      TCPSocket.open(host, proxy_port, &:close)
      return
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      raise "WEBrick proxy did not start on #{host}:#{proxy_port}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.01
    end
  end
end

# These specs cover the HTTPI transport options that Faraday users now set on
# `client.faraday`. Each group checks one option family against a real local
# Rack/Puma server because auth, redirects, and TLS are easy to fake in ways
# that miss the adapter behavior.
#
# The servers bind to ephemeral loopback ports so this file can run alongside
# integration specs without port collisions.
server_cluster = nil

RSpec.describe "Savon Faraday transport - connection options" do
  before :all do
    server_cluster = FaradayTransportOptionServers.start
  end

  after :all do
    server_cluster&.stop
  end

  let(:servers) { server_cluster }

  # Plain HTTP client for tests that do not need TLS.
  def http_client(extra = {})
    Savon.client(
      { endpoint: servers.http_server.url(:repeat),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false }.merge(extra)
    )
  end

  # HTTPS client for server-certificate and TLS-version tests.
  def https_client(extra = {}, &block)
    client = Savon.client(
      { endpoint: servers.https_server.url(:repeat),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false }.merge(extra)
    )
    yield client if block
    client
  end

  # mTLS client for tests where the server requires a client certificate.
  def mtls_client(extra = {}, &block)
    client = Savon.client(
      { endpoint: servers.mtls_server.url(:repeat),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false }.merge(extra)
    )
    yield client if block
    client
  end

  def make_call(client)
    client.call(:authenticate, message: { symbol: "AAPL" })
  end

  def ca_file
    IntegrationServer.ssl_ca_file
  end

  def certificate_dir
    File.dirname(ca_file)
  end

  def client_key
    File.read(File.join(certificate_dir, "client.key"))
  end

  def client_cert
    File.read(File.join(certificate_dir, "client.cert"))
  end

  def client_encrypted_key
    File.join(certificate_dir, "client_encrypted.key")
  end

  # Timeouts
  describe "open_timeout" do
    it "fails quickly when opening a connection to a non-routable endpoint" do
      client = Savon.client(
        endpoint: "http://192.0.2.0:81",
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
      client.faraday.options.open_timeout = 0.1
      client.faraday.options.read_timeout = 5

      expect {
        Timeout.timeout(2) { client.call(:authenticate) }
      }.to raise_error(
        ->(e) { e.is_a?(Faraday::ConnectionFailed) || e.is_a?(Faraday::TimeoutError) }
      )
    end
  end

  describe "read_timeout" do
    it "raises a timeout error when the server does not respond within the timeout" do
      client = Savon.client(
        endpoint: servers.http_server.url(:timeout),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
      client.faraday.options.read_timeout = 0.1

      expect { client.call(:authenticate) }.to raise_error(Faraday::TimeoutError)
    end
  end

  describe "write_timeout" do
    it "propagates write_timeout to the underlying net_http connection" do
      observed_write_timeout = nil
      client = http_client
      client.faraday.options.write_timeout = 7
      client.faraday.adapter :net_http do |http|
        observed_write_timeout = http.write_timeout
      end

      make_call(client)
      expect(observed_write_timeout).to eq(7)
    end
  end

  # Proxy
  describe "proxy" do
    it "routes requests through the proxy server" do
      servers.proxy_requests.clear

      client = http_client
      client.faraday.proxy = servers.proxy_url
      make_call(client)

      expect(servers.proxy_requests).not_to be_empty
    end
  end

  # Adapter
  describe "adapter" do
    it "uses the configured adapter for the connection" do
      client = http_client
      client.faraday.adapter :net_http

      # In Faraday 2 the adapter sits outside the request/response middleware
      # stack, so `builder.handlers` will not show it.
      expect(client.faraday.builder.adapter.klass).to eq(Faraday::Adapter::NetHttp)
    end

    it "successfully makes a SOAP call with the net_http adapter" do
      client = http_client
      client.faraday.adapter :net_http
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  # Basic auth
  describe "basic_auth" do
    it "succeeds with correct credentials" do
      client = Savon.client(
        endpoint: servers.http_server.url(:basic_auth),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false,
        raise_errors: false
      )
      client.faraday.request :authorization, :basic, "admin", "secret"
      response = client.call(:authenticate)
      expect(response.http.code).to eq(200)
    end

    it "raises Savon::HTTPError with wrong credentials" do
      client = Savon.client(
        endpoint: servers.http_server.url(:basic_auth),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
      client.faraday.request :authorization, :basic, "admin", "wrong"
      expect { client.call(:authenticate) }.to raise_error(Savon::HTTPError)
    end
  end

  # Digest auth
  describe "digest_auth" do
    it "succeeds with correct credentials" do
      client = Savon.client(
        endpoint: servers.http_server.url(:digest_auth),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false,
        raise_errors: false
      )
      client.faraday.request :digest, "admin", "secret"
      response = client.call(:authenticate)
      expect(response.http.code).to eq(200)
    end

    it "raises Savon::HTTPError with wrong credentials" do
      client = Savon.client(
        endpoint: servers.http_server.url(:digest_auth),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
      client.faraday.request :digest, "admin", "wrong"
      expect { client.call(:authenticate) }.to raise_error(Savon::HTTPError)
    end
  end

  # NTLM auth
  describe "ntlm" do
    # NTLM has to reuse the TCP connection between the Type2 challenge and the
    # Type3 response, so this middleware needs net_http_persistent. The domain
    # field must be an empty string rather than nil because rubyntlm serializes
    # it as a buffer and calls #size.
    def ntlm_client(creds, raise_errors: false)
      client = Savon.client(
        endpoint: servers.http_server.url(:ntlm_auth),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false,
        raise_errors: raise_errors
      )
      client.faraday.adapter :net_http_persistent
      client.faraday.request :ntlm_auth, auth: creds
      client
    end

    it "succeeds with correct credentials" do
      response = ntlm_client(["admin", "secret", ""]).call(:authenticate)
      expect(response.http.code).to eq(200)
    end

    it "raises Savon::HTTPError with wrong credentials" do
      # The test server requests NTLM2 session responses, which lets rubyntlm
      # reject the wrong password instead of taking its older NTLMv1/NTLMv2
      # branches.
      client = Savon.client(
        endpoint: servers.http_server.url(:ntlm_auth),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
      client.faraday.adapter :net_http_persistent
      client.faraday.request :ntlm_auth, auth: ["admin", "wrong", ""]
      expect { client.call(:authenticate) }.to raise_error(Savon::HTTPError)
    end

    it "raises Savon::HTTPError with the wrong username" do
      client = ntlm_client(["wrong", "secret", ""], raise_errors: true)
      expect { client.call(:authenticate) }.to raise_error(Savon::HTTPError)
    end

    it "raises Savon::HTTPError with the wrong domain" do
      client = ntlm_client(%w[admin secret wrong-domain], raise_errors: true)
      expect { client.call(:authenticate) }.to raise_error(Savon::HTTPError)
    end
  end

  # Follow redirects
  describe "follow_redirects" do
    it "raises Savon::HTTPError when the server redirects and no middleware is configured" do
      client = Savon.client(
        endpoint: servers.http_server.url(:redirect),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
      expect { client.call(:authenticate) }.to raise_error(Savon::HTTPError)
    end

    it "follows the redirect and returns a Savon::Response when the middleware is active" do
      client = Savon.client(
        endpoint: servers.http_server.url(:redirect),
        namespace: "http://v1.example.com",
        transport: :faraday,
        log: false
      )
      # Register this as response middleware. In Faraday 2,
      # `conn.use :follow_redirects` looks for ordinary middleware and raises.
      # The server returns 307 so the redirected SOAP request stays a POST; see
      # /redirect in application.rb for the 302 failure mode.
      client.faraday.response :follow_redirects
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  # SSL: server certificate verification against the HTTPS server
  describe "ssl_verify_mode" do
    it "succeeds with VERIFY_PEER when the CA is trusted" do
      client = https_client
      client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER
      client.faraday.ssl.ca_file     = ca_file
      expect(make_call(client)).to be_a(Savon::Response)
    end

    it "succeeds with VERIFY_NONE without supplying a CA" do
      client = https_client
      client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_NONE
      expect(make_call(client)).to be_a(Savon::Response)
    end

    it "raises Faraday::SSLError with VERIFY_PEER and no CA" do
      client = https_client
      client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER
      expect { make_call(client) }.to raise_error(Faraday::SSLError)
    end
  end

  describe "ssl_ca_cert_file" do
    it "trusts the server cert when the CA file is set" do
      client = https_client
      client.faraday.ssl.ca_file = ca_file
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "ssl_ca_cert_path" do
    it "trusts the server cert when the CA directory is set" do
      client = https_client
      client.faraday.ssl.ca_path = servers.ca_path
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "ssl_ca_cert" do
    it "trusts the server cert when the CA certificate is added to a store" do
      store = OpenSSL::X509::Store.new
      store.add_cert(OpenSSL::X509::Certificate.new(File.read(ca_file)))

      client = https_client
      client.faraday.ssl.cert_store = store
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "ssl_cert_store" do
    it "trusts the server cert when a configured certificate store is supplied" do
      store = OpenSSL::X509::Store.new
      store.add_cert(OpenSSL::X509::Certificate.new(File.read(ca_file)))

      client = https_client
      client.faraday.ssl.cert_store = store
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "ssl_version" do
    it "completes the request successfully with an explicit TLS version" do
      client = https_client
      client.faraday.ssl.ca_file = ca_file
      client.faraday.ssl.version = "TLSv1_2"
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "ssl_min_version" do
    it "completes the request successfully with a minimum TLS version set" do
      client = https_client
      client.faraday.ssl.ca_file     = ca_file
      client.faraday.ssl.min_version = OpenSSL::SSL::TLS1_2_VERSION
      expect(make_call(client)).to be_a(Savon::Response)
    end

    it "raises Faraday::SSLError when min_version exceeds max_version" do
      # min > max gives OpenSSL no protocol version it can negotiate. That is a
      # direct check that both bounds reached the SSL context.
      client = https_client
      client.faraday.ssl.ca_file     = ca_file
      client.faraday.ssl.min_version = OpenSSL::SSL::TLS1_3_VERSION
      client.faraday.ssl.max_version = OpenSSL::SSL::TLS1_2_VERSION
      expect { make_call(client) }.to raise_error(Faraday::SSLError)
    end
  end

  describe "ssl_max_version" do
    it "completes the request successfully with a maximum TLS version set" do
      client = https_client
      client.faraday.ssl.ca_file     = ca_file
      client.faraday.ssl.max_version = OpenSSL::SSL::TLS1_3_VERSION
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "ssl_ciphers" do
    it "completes the request successfully with an explicit cipher string" do
      client = https_client
      client.faraday.ssl.ca_file = ca_file
      client.faraday.ssl.ciphers = "ECDHE-RSA-AES256-GCM-SHA384"
      expect(make_call(client)).to be_a(Savon::Response)
    end

    it "raises Faraday::SSLError when only ECDSA ciphers are offered to an RSA server" do
      # TLS 1.3 ignores `ssl.ciphers`, so pin this failure to TLS 1.2. Then
      # offer only ECDSA cipher suites to a server with an RSA certificate; no
      # shared suite exists.
      client = https_client
      client.faraday.ssl.ca_file     = ca_file
      client.faraday.ssl.max_version = OpenSSL::SSL::TLS1_2_VERSION
      client.faraday.ssl.ciphers     = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256"
      expect { make_call(client) }.to raise_error(Faraday::SSLError)
    end
  end

  # mTLS: client certificates against the mTLS server
  describe "ssl_cert_key_file / ssl_cert_file" do
    it "succeeds when client key and cert are loaded from files" do
      client = mtls_client
      client.faraday.ssl.ca_file      = ca_file
      client.faraday.ssl.client_key   = OpenSSL::PKey.read(File.read(
                                                             File.join(certificate_dir, "client.key")
                                                           ))
      client.faraday.ssl.client_cert = OpenSSL::X509::Certificate.new(File.read(
                                                                        File.join(certificate_dir, "client.cert")
                                                                      ))
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "ssl_cert_key / ssl_cert" do
    it "succeeds when client key and cert are passed as already-loaded objects" do
      pkey = OpenSSL::PKey.read(client_key)
      cert = OpenSSL::X509::Certificate.new(client_cert)

      client = mtls_client
      client.faraday.ssl.ca_file     = ca_file
      client.faraday.ssl.client_key  = pkey
      client.faraday.ssl.client_cert = cert
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "ssl_cert_key_password" do
    it "succeeds when the client key is encrypted and the password is supplied" do
      pkey = OpenSSL::PKey.read(File.read(client_encrypted_key), "test-password")
      cert = OpenSSL::X509::Certificate.new(client_cert)

      client = mtls_client
      client.faraday.ssl.ca_file     = ca_file
      client.faraday.ssl.client_key  = pkey
      client.faraday.ssl.client_cert = cert
      expect(make_call(client)).to be_a(Savon::Response)
    end
  end

  describe "mTLS baseline" do
    it "raises an SSL or connection error when no client cert is provided to the mTLS server" do
      client = mtls_client
      client.faraday.ssl.ca_file = ca_file
      # Some stacks report this failed mTLS handshake as SSL. Puma closes the
      # socket early enough that Faraday may wrap it as ConnectionFailed. Either
      # way, no request can complete without a client certificate.
      expect { make_call(client) }.to raise_error(
        ->(e) { e.is_a?(Faraday::SSLError) || e.is_a?(Faraday::ConnectionFailed) }
      )
    end
  end
end
