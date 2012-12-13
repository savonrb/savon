require "bundler"
Bundler.require :default, :development

RSpec.configure do |config|
  config.mock_with :mocha
  config.order = "random"
end

# TODO: replace with alternative impl. [dh, 2012-12-13]
#Savon.config.log = false
HTTPI.log = false

require "support/endpoint"
require "support/fixture"
