FakeWeb.allow_net_connect = false

# Some WSDL and SOAP request.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint, :body => WSDLFixture.authentication
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint, :body => ResponseFixture.authentication

# WSDL and SOAP request with a Savon::SOAPFault.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint(:soap_fault), :body => WSDLFixture.authentication
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint(:soap_fault), :body => ResponseFixture.soap_fault

# WSDL and SOAP request with a Savon::HTTPError.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint(:http_error), :body => WSDLFixture.authentication
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint(:http_error), :body => "", :status => ["404", "Not Found"]

# WSDL and SOAP request with an invalid endpoint.
FakeWeb.register_uri :get, EndpointHelper.wsdl_endpoint(:invalid), :body => ""
FakeWeb.register_uri :post, EndpointHelper.soap_endpoint(:invalid), :body => "", :status => ["404", "Not Found"]
