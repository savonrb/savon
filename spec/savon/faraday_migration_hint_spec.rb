# frozen_string_literal: true

require "spec_helper"
require "openssl"

RSpec.describe Savon::FaradayMigrationHint do
  def hint_for(option, value)
    described_class.new(option, value).message
  end

  def expected_hints
    {
      proxy: ["http://proxy:8080", '  proxy - Use: client.faraday.proxy = "http://proxy:8080"'],
      open_timeout: [1, "  open_timeout - Use: client.faraday.options.open_timeout = 1"],
      read_timeout: [1, "  read_timeout - Use: client.faraday.options.read_timeout = 1"],
      write_timeout: [1, "  write_timeout - Use: client.faraday.options.write_timeout = 1"],
      ssl_version: ["TLSv1_2", '  ssl_version - Use: client.faraday.ssl.version = "TLSv1_2"'],
      ssl_min_version: ["TLS1_2", '  ssl_min_version - Use: client.faraday.ssl.min_version = "TLS1_2"'],
      ssl_max_version: ["TLS1_3", '  ssl_max_version - Use: client.faraday.ssl.max_version = "TLS1_3"'],
      ssl_verify_mode: [
        :peer,
        "  ssl_verify_mode - Use: client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER"
      ],
      ssl_cert_key_file: ["client.key", ssl_cert_key_file_hint],
      ssl_cert_key: ["key", "  ssl_cert_key - Use: client.faraday.ssl.client_key = key"],
      ssl_cert_key_password: ["password", ssl_cert_key_password_hint],
      ssl_cert_file: ["client.cert", ssl_cert_file_hint],
      ssl_cert: ["cert", "  ssl_cert - Use: client.faraday.ssl.client_cert = cert"],
      ssl_ca_cert_file: ["ca.pem", '  ssl_ca_cert_file - Use: client.faraday.ssl.ca_file = "ca.pem"'],
      ssl_ca_cert: ["cert", ssl_ca_cert_hint],
      ssl_ciphers: ["AES256", '  ssl_ciphers - Use: client.faraday.ssl.ciphers = "AES256"'],
      ssl_ca_cert_path: ["certs", '  ssl_ca_cert_path - Use: client.faraday.ssl.ca_path = "certs"'],
      ssl_cert_store: [Object.new, "  ssl_cert_store - Use: client.faraday.ssl.cert_store = store"],
      basic_auth: [%w[user pass], "  basic_auth - Use: client.faraday.request :authorization, :basic, user, pass"],
      digest_auth: [%w[user pass], digest_auth_hint],
      ntlm: [%w[user pass domain], ntlm_hint],
      follow_redirects: [true, follow_redirects_hint],
      adapter: [:httpclient, httpclient_adapter_hint]
    }
  end

  def ssl_cert_key_file_hint
    "  ssl_cert_key_file - Use:\n" \
      "    key = OpenSSL::PKey.read(File.read(\"client.key\"))\n" \
      "    client.faraday.ssl.client_key = key"
  end

  def ssl_cert_key_password_hint
    "  ssl_cert_key_password - Use:\n" \
      "    key = OpenSSL::PKey.read(File.read(key_path), password)\n" \
      "    client.faraday.ssl.client_key = key"
  end

  def ssl_cert_file_hint
    "  ssl_cert_file - Use:\n" \
      "    cert = OpenSSL::X509::Certificate.new(File.read(\"client.cert\"))\n" \
      "    client.faraday.ssl.client_cert = cert"
  end

  def ssl_ca_cert_hint
    "  ssl_ca_cert - Use:\n" \
      "    store = OpenSSL::X509::Store.new\n" \
      "    store.set_default_paths\n" \
      "    store.add_cert(cert)\n" \
      "    client.faraday.ssl.cert_store = store"
  end

  def digest_auth_hint
    "  digest_auth - Use:\n" \
      "    gem 'faraday-digestauth'\n" \
      "    require 'faraday/digestauth'\n" \
      "    client.faraday.request :digest, user, pass"
  end

  def ntlm_hint
    "  ntlm - Use:\n" \
      "    gem 'faraday-ntlm_auth'\n" \
      "    require 'faraday/ntlm_auth'\n" \
      "    client.faraday.adapter :net_http_persistent\n" \
      "    client.faraday.request :ntlm_auth, auth: [user, pass, domain]"
  end

  def follow_redirects_hint
    "  follow_redirects - Use:\n" \
      "    gem 'faraday-follow_redirects'\n" \
      "    require 'faraday/follow_redirects'\n" \
      "    client.faraday.response :follow_redirects"
  end

  def httpclient_adapter_hint
    "  adapter - Use:\n" \
      "    gem 'faraday-httpclient'\n" \
      "    require 'faraday/httpclient'\n" \
      "    client.faraday.adapter :httpclient"
  end

  it "builds the exact migration hint for every incompatible global option" do
    expect(expected_hints.keys).to match_array(Savon::HTTPITransportOptions::FARADAY_INCOMPATIBLE_GLOBALS)

    expected_hints.each do |option, (value, expected_hint)|
      expect(hint_for(option, value)).to eq(expected_hint)
    end
  end

  it "redacts proxy userinfo and drops URL params from the migration hint" do
    hint = hint_for(:proxy, "http://admin:secret@proxy.example.test:8080/path?token=abc#fragment")

    expect(hint).to eq('  proxy - Use: client.faraday.proxy = "http://...@proxy.example.test:8080"')
    expect(hint).not_to include("admin")
    expect(hint).not_to include("secret")
    expect(hint).not_to include("token")
  end

  it "maps each known ssl_verify_mode value to the matching OpenSSL constant" do
    expect(hint_for(:ssl_verify_mode, :none)).to include("OpenSSL::SSL::VERIFY_NONE")
    expect(hint_for(:ssl_verify_mode, :peer)).to include("OpenSSL::SSL::VERIFY_PEER")
    expect(hint_for(:ssl_verify_mode, :fail_if_no_peer_cert)).to include("OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT")
    expect(hint_for(:ssl_verify_mode, :client_once)).to include("OpenSSL::SSL::VERIFY_CLIENT_ONCE")
  end

  it "uses a generic ssl_verify_mode hint when the value is not an HTTPI symbol" do
    expect(hint_for(:ssl_verify_mode, OpenSSL::SSL::VERIFY_PEER))
      .to eq("  ssl_verify_mode - Use: client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER or OpenSSL::SSL::VERIFY_NONE")
  end

  it "gives adapter-specific hints when there is a known Faraday adapter gem" do
    expect(hint_for(:adapter, :net_http)).to eq("  adapter - Use: client.faraday.adapter :net_http")
    expect(hint_for(:adapter, :excon)).to include("gem 'faraday-excon'")
    expect(hint_for(:adapter, :net_http_persistent)).to include("gem 'faraday-net_http_persistent'")
  end

  it "falls back to a generic adapter hint for custom HTTPI adapters" do
    expect(hint_for(:adapter, :fake_adapter_for_test))
      .to include("choose and install a Faraday adapter matching :fake_adapter_for_test")
  end
end
