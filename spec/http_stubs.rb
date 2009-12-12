require "fakeweb"

FakeWeb.allow_net_connect = false

# Some WSDL and SOAP request.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint, :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint, :body => UserFixture.user_response

# WSDL and SOAP request with multiple "//return" nodes.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint(:multiple), :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint(:multiple), :body => UserFixture.multiple_user_response

# WSDL and SOAP request with a Savon::SOAPFault.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint(:soap_fault), :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint(:soap_fault), :body => UserFixture.soap_fault

# WSDL and SOAP request with a Savon::HTTPError.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint(:http_error), :body => UserFixture.user_wsdl
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint(:http_error), :body => "", :status => ["404", "Not Found"]

# WSDL and SOAP request with an invalid endpoint.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint(:invalid), :body => ""
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint(:invalid), :body => "", :status => ["404", "Not Found"]
