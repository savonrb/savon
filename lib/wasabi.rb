require 'logging'

require 'wasabi/version'
require 'wasabi/errors'
require 'wasabi/document'
require 'wasabi/resolver'
require 'wasabi/importer'
require 'wasabi/operation_builder'

class Wasabi

  XSD  = 'http://www.w3.org/2001/XMLSchema'
  WSDL = 'http://schemas.xmlsoap.org/wsdl/'

  SOAP_1_1 = 'http://schemas.xmlsoap.org/wsdl/soap/'
  SOAP_1_2 = 'http://schemas.xmlsoap.org/wsdl/soap12/'

  def initialize(wsdl, http = nil)
    resolver = Resolver.new(http)
    importer = Importer.new(resolver, self)

    @documents, @schemas = importer.import(wsdl)
  end

  attr_reader :documents, :schemas

  def service_name
    @documents.service_name
  end

  # XXX: check if we can get rid of this method.
  def target_namespace
    @documents.target_namespace
  end

  # Public: Returns a Hash of services and ports defined by the WSDL.
  def services
    @services ||= begin
      services = {}

      @documents.services.each do |service_name, service|
        ports = service.ports.map { |port_name, port|
          [port_name, { :type => port.type, :location => port.location }]
        }
        services[service_name] = { :ports => Hash[ports] }
      end

      services
    end
  end

  # Public: Returns an Hash of operation names to Operations by service and port name.
  def operations(service_name, port_name)
    verify_service_exists! service_name
    verify_port_exists! service_name, port_name

    OperationBuilder.new(service_name, port_name, self).build
  end

  # Public: Returns an Operation by service, port and operation name.
  def operation(service_name, port_name, operation_name)
    operations = operations(service_name, port_name)
    verify_operation_exists! operations, service_name, port_name, operation_name

    operations[operation_name]
  end

  private

  # Private: Raises a useful error in case the operation does not exist.
  def verify_operation_exists!(operations, service_name, port_name, operation_name)
    unless operations.include? operation_name
      raise ArgumentError, "Unknown operation #{operation_name.inspect} for " \
                           "service #{service_name.inspect} and port #{port_name.inspect}.\n" \
                           "You may want to try one of #{operations.keys.inspect}."
    end
  end

  # Private: Raises a useful error in case the service does not exist.
  def verify_service_exists!(service_name)
    unless services.include? service_name
      raise ArgumentError, "Unknown service #{service_name.inspect}.\n" \
                           "You may want to try one of #{services.keys.inspect}."
    end
  end

  # Private: Raises a useful error in case the port does not exist.
  def verify_port_exists!(service_name, port_name)
    ports = services.fetch(service_name)[:ports]

    unless ports.include? port_name
      raise ArgumentError, "Unknown port #{port_name.inspect} for service #{service_name.inspect}.\n" \
                           "You may want to try one of #{ports.keys.inspect}."
    end
  end

end
