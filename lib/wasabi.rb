require 'wasabi/version'
require 'wasabi/document'
require 'wasabi/resolver'
require 'wasabi/importer'
require 'wasabi/inspector'

class Wasabi

  XSD  = 'http://www.w3.org/2001/XMLSchema'
  WSDL = 'http://schemas.xmlsoap.org/wsdl/'

  SOAP_1_1 = 'http://schemas.xmlsoap.org/wsdl/soap/'
  SOAP_1_2 = 'http://schemas.xmlsoap.org/wsdl/soap12/'

  def initialize(wsdl, request = nil)
    resolver = Resolver.new(request)
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

  def namespaces
    @documents.namespaces
  end

  def operation(operation_name)
    @documents.operations[operation_name]
  end

  def inspect
    Inspector.new(self)
  end

end
