require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
  # add :focus => true to a #describe, #context or #it to filter rspec to only run those examples
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

require "savon"

# Disable logging for specs.
Savon.log = false

require "support/endpoint"
require "support/fixture"


