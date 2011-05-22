require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
end

require "savon"

# Disable logging for specs.
Savon.log = false

Dir["spec/support/**/*.rb"].each { |file| require file }
