require "rubygems"
require "rake"
gem "rspec", ">= 1.2.8"
require "spec"
require "mocha"

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

require "savon"
Savon::Request.log = false

# Load fixture helpers.
FileList["spec/fixtures/**/*.rb"].each { |fixture| require fixture }

# Load endpoint helper.
require "endpoint_helper"

# Set up endpoint stubs.
require "fakeweb"
require "http_stubs"
