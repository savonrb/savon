require "rubygems"
gem "rspec", ">= 1.2.8"
require "spec"
require "rr"
require "fakeweb"

Spec::Runner.configure do |config|
  config.mock_with :rr
end

require "savon"
Savon::HTTP.logger = nil

class SpecHelper
  class << self

    def some_endpoint
      "http://example.com?wsdl"
    end

    def some_endpoint_uri
      URI some_endpoint
    end

  end
end

require "fixtures/user_fixture"

# WSDL request
FakeWeb.register_uri :get, SpecHelper.some_endpoint, :body => UserFixture.user_wsdl