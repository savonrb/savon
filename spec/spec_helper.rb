require "rubygems"
gem "rspec", ">= 1.2.8"
require "spec"
require "rr"

require File.join File.dirname(__FILE__), "..", "lib", "savon"

Spec::Runner.configure do |config|
  config.mock_with :rr
end
=begin
module SpecHelperMethods

  def some_url
    "http://example.com"
  end

  def some_uri
    URI some_url
  end

  def some_http
    Net::HTTP.new some_uri.host, some_uri.port
  end

  def some_savon_http_instance
    Savon::HTTP.new URI("http://example.com")
  end

end
=end
class UserFixture
  extend RR::Adapters::RRMethods
#  include SpecHelperMethods

  class << self
=begin
    def namespace_uri
      "http://v1_0.ws.user.example.com"
    end

    def soap_actions
      %w(findUser)
    end

    def choice_elements
      %w(idCredential emailCredential)
    end
=end
    def user_wsdl
      load_fixture "user_wsdl.xml"
    end

    def user_response
      load_fixture "user_response.xml"
    end

    def soap_fault
      load_fixture "soap_fault.xml"
    end
=begin
    def http_response_mock(options = {})
      response_body = options[:soap_fault] ? soap_fault : user_response
      response_code = options[:http_error] ? 500 : 200
      response_body = "" if options[:http_error] && !options[:soap_fault]
      generate_http_mock soap_response_mock(response_body, response_code)
    end

    def http_wsdl_mock(options {})
      response_body = options[:invalid] ? "invalid" : user_wsdl
      generate_http_mock soap_response_mock(response_body, 200)
    end
=end
  private

    def load_fixture(file)
      file_path = File.join File.dirname(__FILE__), "fixtures", file
      IO.readlines(file_path, "").to_s
    end
=begin
    def generate_http_mock(soap_response)
      mock = some_http
      stub(mock).get(anything) { wsdl_response_mock(user_wsdl) }
      stub(mock).request_post(anything, anything, anything) { soap_response }
      mock
    end

    def wsdl_response_mock(response_body)
      mock = mock()
      stub(mock).body { response_body }
      mock
    end

    def soap_response_mock(response_body, response_code)
      mock = mock()
      stub(mock).body { response_body }
      stub(mock).code { response_code }
      stub(mock).message { "whatever" }
      mock
    end
=end
  end
end

=begin
module SpecHelper
  def some_url
    "http://example.com"
  end

  def some_uri
    URI(some_url)
  end

  def some_http
    Net::HTTP.new(some_uri.host, some_uri.port)
  end

  def new_wsdl
    Savon::WSDL.new(some_uri, UserFixture.http_mock)
  end

  def new_service_instance(options = {})
    service = Savon::Service.new(some_url)
    service.instance_variable_set("@http", UserFixture.http_mock(options))
    service
  end
end
=end

