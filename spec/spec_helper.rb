require "rspec"
require "mocha"

spec = File.expand_path("..", __FILE__)
$:.unshift spec unless $:.include? spec

RSpec.configure do |config|
  config.mock_with :mocha
end

require "savon"

# Disable logging for specs.
Savon.log = false

# Requires fixtures.
Dir[File.expand_path("../fixtures/**/*.rb", __FILE__)].each { |file| require file }

# Requires supporting files.
require "support/endpoint"
