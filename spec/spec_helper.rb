require "rubygems"
gem "rspec", ">= 1.2.8"
require "spec"
require "rr"

Spec::Runner.configure do |config|
  config.mock_with :rr
end

require "savon"
Savon::HTTP.logger = nil

require "fixtures/user_fixture"
require "spec_helper_methods"
require "http_stubs"