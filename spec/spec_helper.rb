require "rubygems"
require "rake"
require "spec"
require "mocha"
require "fakeweb"

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

require "savon"
Savon::Request.log = false

FileList["spec/fixtures/**/*.rb"].each { |fixture| require fixture }
require "endpoint_helper"
require "http_stubs"
