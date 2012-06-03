require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
end

Savon.configure do |config|
  config.logger = Savon::NullLogger.new
end

HTTPI.log = false

require "support/endpoint"
require "support/fixture"
