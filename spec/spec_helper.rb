# frozen_string_literal: true
require "bundler"
require "byebug"
Bundler.setup(:default, :development)

unless RUBY_PLATFORM =~ /java/
  require "simplecov"
  SimpleCov.start do
      add_filter "spec"
  end
end

require "savon"
require "rspec"

support_files = File.expand_path("spec/support/**/*.rb")
Dir[support_files].sort.each { |file| require file }

RSpec.configure do |config|
  config.include SpecSupport
  config.mock_with :mocha
  config.order = "random"
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
end

