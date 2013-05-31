require "savon/version"
require "savon/errors"
require "savon/operation"
require "savon/httpclient"
require "wasabi"

class Savon

  def self.http_client
    HTTPClient
  end

  def initialize(wsdl, http = nil)
    @http = http || new_http_client
    @wsdl = Wasabi.new(wsdl, @http)
  end

  attr_reader :wsdl

  def http
    @http.client
  end

  def services
    @wsdl.services
  end

  def operations(service, port)
    @wsdl.operations(service.to_s, port.to_s).keys.sort
  end

  # TODO: check if the operation exists
  def operation(service, port, operation)
    op = @wsdl.operation(service.to_s, port.to_s, operation.to_s)
    Operation.new(op, @wsdl, @http)
  end

  def call(service, port, operation, options = {})
    operation(service, port, operation).call(options)
  end

  private

  def new_http_client
    self.class.http_client.new
  end

end
