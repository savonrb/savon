require "rspec"
require "mocha"
require "fakeweb"

RSpec.configure do |config|
  config.mock_with :mocha
end

require "savon"
Savon::Request.log = false

# Requires fixtures.
Dir["spec/fixtures/**/*.rb"].each {|file| require file }

# Requires supporting files.
require "support/endpoint_helper"
require "support/http_stubs"
