require "rake"
require "spec"
require "mocha"
require "fakeweb"

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

require "savon"
Savon::Request.log = false
