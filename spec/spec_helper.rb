require "bundler"
Bundler.setup(:default, :development)

require "savon"
require "rspec"

RSpec.configure do |config|
  config.mock_with :mocha
  config.order = "random"
end

HTTPI.log = false

require "support/endpoint"
require "support/fixture"
