require "rubygems"
require "fakeweb"

FakeWeb.allow_net_connect = false

# Register fake WSDL and SOAP request.
FakeWeb.register_uri :get, SpecHelper.some_endpoint, :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, SpecHelper.soap_call_endpoint, :body => UserFixture.user_response

# Register fake WSDL and SOAP request with multiple "//return" nodes.
FakeWeb.register_uri :get, SpecHelper.multiple_endpoint, :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, SpecHelper.soap_multiple_endpoint, :body => UserFixture.multiple_user_response

# Register fake WSDL and SOAP request for a Savon::SOAPFault.
FakeWeb.register_uri :get, SpecHelper.soapfault_endpoint, :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, SpecHelper.soap_soapfault_endpoint, :body => UserFixture.soap_fault

# Register fake WSDL and SOAP request for a Savon::HTTPError.
FakeWeb.register_uri :get, SpecHelper.httperror_endpoint, :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, SpecHelper.soap_httperror_endpoint, :body => "",
  :status => ["404", "Not Found"]