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

# don't have HTTPI lazy-load HTTPClient, because then
# it can't actually be refered to inside the specs.
require "httpclient"

require "support/endpoint"
require "support/fixture"
