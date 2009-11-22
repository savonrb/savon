class SpecHelper
  
  @soap_call_endpoint = "http://services.example.com/UserService"
  @some_endpoint = @soap_call_endpoint + "?wsdl"
  @some_endpoint_uri = URI @some_endpoint

  @soap_soapfault_endpoint = "http://soapfault.example.com/UserService"
  @soapfault_endpoint = @soap_soapfault_endpoint + "?wsdl"

  @soap_httperror_endpoint = "http://httperror.example.com/UserService"
  @httperror_endpoint = @soap_httperror_endpoint + "?wsdl"
  
  @wsse_security_nodes =  ["wsse:Security", "wsse:UsernameToken",
    "wsse:Username", "wsse:Password", "wsse:Nonce", "wsu:Created"]

  class << self
    attr_accessor :soap_call_endpoint, :some_endpoint, :some_endpoint_uri,
      :soap_soapfault_endpoint, :soapfault_endpoint,
      :soap_httperror_endpoint, :httperror_endpoint,
      :wsse_security_nodes
  end

end