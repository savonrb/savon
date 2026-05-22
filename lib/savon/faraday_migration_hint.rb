# frozen_string_literal: true

require "uri"

module Savon
  # Formats the replacement Faraday setup for one HTTPI-only option.
  class FaradayMigrationHint
    VALUE_AWARE_OPTIONS = %i[
      proxy
      open_timeout
      read_timeout
      write_timeout
      ssl_version
      ssl_min_version
      ssl_max_version
      ssl_verify_mode
      ssl_cert_key_file
      ssl_cert_file
      ssl_ca_cert_file
      ssl_ciphers
      ssl_ca_cert_path
      adapter
    ].freeze

    STATIC_HINTS = {
      ssl_cert_key: "client.faraday.ssl.client_key = key",
      ssl_cert_key_password: [
        "key = OpenSSL::PKey.read(File.read(key_path), password)",
        "client.faraday.ssl.client_key = key"
      ],
      ssl_cert: "client.faraday.ssl.client_cert = cert",
      ssl_ca_cert: [
        "store = OpenSSL::X509::Store.new",
        "store.set_default_paths",
        "store.add_cert(cert)",
        "client.faraday.ssl.cert_store = store"
      ],
      ssl_cert_store: "client.faraday.ssl.cert_store = store",
      basic_auth: "client.faraday.request :authorization, :basic, user, pass",
      digest_auth: [
        "gem 'faraday-digestauth'",
        "require 'faraday/digestauth'",
        "client.faraday.request :digest, user, pass"
      ],
      ntlm: [
        "gem 'faraday-ntlm_auth'",
        "require 'faraday/ntlm_auth'",
        "client.faraday.adapter :net_http_persistent",
        "client.faraday.request :ntlm_auth, auth: [user, pass, domain]"
      ],
      follow_redirects: [
        "gem 'faraday-follow_redirects'",
        "require 'faraday/follow_redirects'",
        "client.faraday.response :follow_redirects"
      ]
    }.freeze

    OPTIONS = (VALUE_AWARE_OPTIONS + STATIC_HINTS.keys).freeze

    def initialize(option, value)
      @option = option
      @value = value
    end

    def message
      hint = hint_lines
      return "  #{option} - Use: #{hint}" unless hint.is_a?(Array)

      "  #{option} - Use:\n#{hint.map { |line| "    #{line}" }.join("\n")}"
    end

    private

    attr_reader :option, :value

    def hint_lines
      case option
      when :proxy
        "client.faraday.proxy = #{redacted_proxy_value}"
      when :open_timeout, :read_timeout, :write_timeout
        "client.faraday.options.#{option} = #{value.inspect}"
      when :ssl_version, :ssl_min_version, :ssl_max_version
        ssl_version_hint
      when :ssl_verify_mode
        ssl_verify_mode_hint
      when :ssl_cert_key_file
        ssl_cert_key_file_hint
      when :ssl_cert_file
        ssl_cert_file_hint
      when :ssl_ca_cert_file
        "client.faraday.ssl.ca_file = #{value.inspect}"
      when :ssl_ciphers
        "client.faraday.ssl.ciphers = #{value.inspect}"
      when :ssl_ca_cert_path
        "client.faraday.ssl.ca_path = #{value.inspect}"
      when :adapter
        adapter_hint
      else
        STATIC_HINTS.fetch(option)
      end
    end

    def redacted_proxy_value
      uri = URI.parse(value.to_s)
      return value.inspect unless uri.absolute? && uri.host

      redacted = uri.dup
      redacted.userinfo = "..." if redacted.userinfo
      redacted.path = "" if redacted.respond_to?(:path=)
      redacted.query = nil if redacted.respond_to?(:query=)
      redacted.fragment = nil if redacted.respond_to?(:fragment=)
      redacted.to_s.inspect
    rescue URI::InvalidURIError
      '"[redacted proxy URL]"'
    end

    def ssl_version_hint
      faraday_option = {
        ssl_version: "version",
        ssl_min_version: "min_version",
        ssl_max_version: "max_version"
      }.fetch(option)

      "client.faraday.ssl.#{faraday_option} = #{value.inspect}"
    end

    def ssl_cert_key_file_hint
      [
        "key = OpenSSL::PKey.read(File.read(#{value.inspect}))",
        "client.faraday.ssl.client_key = key"
      ]
    end

    def ssl_cert_file_hint
      [
        "cert = OpenSSL::X509::Certificate.new(File.read(#{value.inspect}))",
        "client.faraday.ssl.client_cert = cert"
      ]
    end

    def adapter_hint
      case value
      when :net_http
        "client.faraday.adapter :net_http"
      when :httpclient
        [
          "gem 'faraday-httpclient'",
          "require 'faraday/httpclient'",
          "client.faraday.adapter :httpclient"
        ]
      when :excon
        [
          "gem 'faraday-excon'",
          "require 'faraday/excon'",
          "client.faraday.adapter :excon"
        ]
      when :net_http_persistent
        [
          "gem 'faraday-net_http_persistent'",
          "require 'faraday/net_http_persistent'",
          "client.faraday.adapter :net_http_persistent"
        ]
      else
        [
          "choose and install a Faraday adapter matching #{value.inspect}",
          "client.faraday.adapter :net_http"
        ]
      end
    end

    def ssl_verify_mode_hint
      case value
      when :none
        "client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_NONE"
      when :peer
        "client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER"
      when :fail_if_no_peer_cert
        "client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT"
      when :client_once
        "client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_CLIENT_ONCE"
      else
        "client.faraday.ssl.verify_mode = OpenSSL::SSL::VERIFY_PEER or OpenSSL::SSL::VERIFY_NONE"
      end
    end
  end
end
