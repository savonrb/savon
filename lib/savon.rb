require 'logging'

require 'savon/version'
require 'savon/errors'
require 'savon/wsdl'
require 'savon/operation'
require 'savon/httpclient'

class Savon

  NS_XSD  = 'http://www.w3.org/2001/XMLSchema'
  NS_WSDL = 'http://schemas.xmlsoap.org/wsdl/'

  NS_SOAP_1_1 = 'http://schemas.xmlsoap.org/wsdl/soap/'
  NS_SOAP_1_2 = 'http://schemas.xmlsoap.org/wsdl/soap12/'

  # Public: Returns the HTTP adapter to use.
  def self.http_adapter
    @http_adapter ||= HTTPClient
  end

  # Public: Sets the HTTP adapter to use.
  def self.http_adapter=(adapter)
    @http_adapter = adapter
  end

  def initialize(wsdl, http = nil)
    @http = http || new_http_client
    @wsdl = WSDL.new(wsdl, @http)
  end

  # Public: Returns the Wasabi instance.
  attr_reader :wsdl

  # Public: Returns the HTTP adapter‘s client instance.
  def http
    @http.client
  end

  # Public: Returns the services and ports defined by the WSDL.
  def services
    @wsdl.services
  end

  # Public: Returns an Array of operations for a service and port.
  def operations(service_name, port_name)
    @wsdl.operations(service_name.to_s, port_name.to_s)
  end

  # Public: Returns an Operation by service, port and operation name.
  def operation(service_name, port_name, operation_name)
    operation = @wsdl.operation(service_name.to_s, port_name.to_s, operation_name.to_s)
    verify_operation_style! operation

    Operation.new(operation, @wsdl, @http)
  end

  private

  # Private: Returns a new instance of the HTTP adapter to use.
  def new_http_client
    self.class.http_adapter.new
  end

  # Private: Raises if the operation style is not supported.
  def verify_operation_style!(operation)
    if operation.input_style == 'rpc/encoded'
     raise UnsupportedStyleError,
           "#{operation.name.inspect} is an #{operation.input_style.inspect} style operation.\n" \
           "Currently this style is not supported."
    end
  end

end
