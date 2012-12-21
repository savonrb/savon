require "bundler"
Bundler.setup(:default, :development)

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require "savon"
require "rspec"

RSpec.configure do |config|
  config.mock_with :mocha
  config.order = "random"
end

HTTPI.log = false

require "support/endpoint"
require "support/fixture"
