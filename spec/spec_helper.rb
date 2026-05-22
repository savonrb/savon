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

# faraday-ntlm_auth does not support Ruby 4 or truffleruby. See Gemfile.
FARADAY_NTLM_AUTH_AVAILABLE = begin
  require "faraday/ntlm_auth"
  true
rescue LoadError
  false
end

# don't have HTTPI lazy-load HTTPClient, because then
# it can't actually be refered to inside the specs.
require "httpclient"

support_files = File.expand_path("spec/support/**/*.rb")
Dir[support_files].sort.each do |file| require file end

RSpec.configure do |config|
  config.include SpecSupport
  config.mock_with :mocha
  config.order = "random"
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
end

HTTPI.log = false
