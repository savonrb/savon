require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
  config.order = 'random'
end

# Silence log output
Savon.config.log = false
HTTPI.log = false

require "support/endpoint"
require "support/fixture"
