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

  def target_namespace
    @documents.target_namespace
  end

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

  def operations(service_name, port_name)
    OperationBuilder.new(service_name, port_name, self).build
  end

  def operation(service_name, port_name, operation_name)
    operations(service_name, port_name)[operation_name]
  end

end
