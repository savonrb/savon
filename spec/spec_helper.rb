require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
end

# Disable logging for specs.
Savon.log = false

support_files = File.expand_path("../../spec/support/**/*.rb", __FILE__)
Dir[support_files].each { |file| require file }
