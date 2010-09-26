require "rspec"
require "mocha"

RSpec.configure do |config|
  config.mock_with :mocha
end

require "savon"
Savon::WSDL::Request.log = false
Savon::SOAP::Request.log = false

# Requires fixtures.
Dir["spec/fixtures/**/*.rb"].each {|file| require file }

# Requires supporting files.
require "support/endpoint"
