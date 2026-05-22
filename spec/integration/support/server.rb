# frozen_string_literal: true

require "puma"
require "puma/minissl"

require "integration/support/application"

# Small Puma wrapper used by integration specs.
#
# It can start plain HTTP, HTTPS, or mTLS. For mTLS pass ssl: true plus ssl_ca_file:
# and ssl_verify_mode:. Pass port: 0 with a concrete loopback host to let the OS pick
# an available port.
class IntegrationServer
  def self.run(options = {})
    server = new(options)
    server.run
    server
  end

  def self.ssl_ca_file   = integration_fixture("ca.pem")
  def self.ssl_key_file  = integration_fixture("server.key")
  def self.ssl_cert_file = integration_fixture("server.cert")

  def self.integration_fixture(file)
    file = File.expand_path("../../fixtures/#{file}", __FILE__)
    raise "No such file '#{file}'" unless File.exist? file

    file
  end

  def initialize(options = {})
    @app = Application
    @host = options.fetch(:host, "localhost")
    @port = options.fetch(:port, 17172)
    @ssl = options.fetch(:ssl, false)
    @ssl_verify_mode = options.fetch(:ssl_verify_mode, Puma::MiniSSL::VERIFY_NONE)
    @ssl_ca_file = options.fetch(:ssl_ca_file, nil)

    @server = Puma::Server.new(app, Puma::Events.new, log_writer: Puma::LogWriter.null)

    if ssl?
      add_ssl_listener
    else
      add_tcp_listener
    end

    assign_bound_port if port.zero?
  end

  attr_reader :app, :host, :port, :server

  def url(path = "")
    protocol = ssl? ? "https" : "http"
    File.join "#{protocol}://#{host}:#{port}/", path.to_s
  end

  def ssl?
    @ssl
  end

  def run
    server.run
  end

  def stop
    server.stop(true)
  end

  private

  def add_tcp_listener
    server.add_tcp_listener(host, port)
  rescue Errno::EADDRINUSE
    raise "Panther is already running at #{url}"
  end

  def add_ssl_listener
    server.add_ssl_listener(host, port, ssl_context)
  end

  def ssl_context
    context = Puma::MiniSSL::Context.new
    context.key = IntegrationServer.ssl_key_file
    context.cert = IntegrationServer.ssl_cert_file
    context.ca = @ssl_ca_file if @ssl_ca_file
    context.verify_mode = @ssl_verify_mode
    context
  end

  def assign_bound_port
    ports = server.connected_ports
    raise "Could not determine bound port for #{host}" if ports.empty?
    raise "Dynamic port requires a single listener for #{host}" if ports.size > 1

    @port = ports.first
  end
end
