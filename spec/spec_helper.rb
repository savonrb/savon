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

class SpecHelper
  
  @soap_call_endpoint = "http://services.example.com/UserService"
  @some_endpoint = @soap_call_endpoint + "?wsdl"
  @some_endpoint_uri = URI @some_endpoint

  @soap_soapfault_endpoint = "http://soapfault.example.com/UserService"
  @soapfault_endpoint = @soap_soapfault_endpoint + "?wsdl"

  @soap_httperror_endpoint = "http://httperror.example.com/UserService"
  @httperror_endpoint = @soap_httperror_endpoint + "?wsdl"

  class << self
    attr_accessor :soap_call_endpoint, :some_endpoint, :some_endpoint_uri,
      :soap_soapfault_endpoint, :soapfault_endpoint,
      :soap_httperror_endpoint, :httperror_endpoint
  end

end

require "fakeweb"
FakeWeb.allow_net_connect = false

# Register fake WSDL and SOAP request.
FakeWeb.register_uri :get, SpecHelper.some_endpoint, :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, SpecHelper.soap_call_endpoint, :body => UserFixture.user_response

# Register fake WSDL and SOAP request for a Savon::SOAPFault.
FakeWeb.register_uri :get, SpecHelper.soapfault_endpoint, :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, SpecHelper.soap_soapfault_endpoint, :body => UserFixture.soap_fault

# Register fake WSDL and SOAP request for a Savon::HTTPError.
FakeWeb.register_uri :get, SpecHelper.httperror_endpoint, :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, SpecHelper.soap_httperror_endpoint, :body => "",
  :status => ["404", "Not Found"]