# frozen_string_literal: true

module IntegrationServerHelper
  # Shared, stateless HTTP test server. Booted once per suite.
  def integration_server
    IntegrationServerHelper.instance
  end

  def self.instance
    @instance ||= IntegrationServer.run
  end

  def self.stop
    @instance&.stop
    @instance = nil
  end
end

RSpec.configure do |config|
  config.include IntegrationServerHelper
  config.after(:suite) { IntegrationServerHelper.stop }
end
