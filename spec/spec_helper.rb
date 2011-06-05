require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
end

# Disable logging and deprecations for specs.
Savon.configure do |config|
  config.log = false
  config.deprecate = false
end

require "support/endpoint"
require "support/fixture"
