require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
end

# Disable logging for specs.
Savon.log = false

require "support/endpoint"
require "support/fixture"
