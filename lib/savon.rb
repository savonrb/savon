require 'logging'
require 'wasabi'

require 'savon/version'
require 'savon/errors'
require 'savon/operation'
require 'savon/httpclient'

class Savon

  # Public: The default HTTP adapter to use.
  def self.http_adapter
    HTTPClient
  end

  def initialize(wsdl, http = nil)
    @http = http || new_http_client
    @wsdl = Wasabi.new(wsdl, @http)
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
    @wsdl.operations(service_name.to_s, port_name.to_s).keys.sort
  end

  # Public: Returns an Operation by service, port and operation name.
  def operation(service_name, port_name, operation_name)
    operation = @wsdl.operation(service_name.to_s, port_name.to_s, operation_name.to_s)
    Operation.new(operation, @wsdl, @http)
  end

  # Public: Calls an operation by service, port and operation name
  # and returns a Response object. Also accepts a Hash of options.
  def call(service_name, port_name, operation_name, options = {})
    operation(service_name, port_name, operation_name).call(options)
  end

  private

  # Private: Returns a new instance of the HTTP adapter to use.
  def new_http_client
    self.class.http_adapter.new
  end

end
