require "rubygems"
require "rake"
require "spec"
require "mocha"
require "fakeweb"

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

require File.dirname(__FILE__) + "/../lib/savon" unless defined? Savon
Savon::Request.log = false

FileList[File.dirname(__FILE__) + "/fixtures/**/*.rb"].each do |fixture|
  require fixture
end
require File.dirname(__FILE__) + "/endpoint_helper"
require File.dirname(__FILE__) + "/http_stubs"
