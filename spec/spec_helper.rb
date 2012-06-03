require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
end

# Silence log output
$stdout = StringIO.new
HTTPI.log = false

require "support/endpoint"
require "support/fixture"
