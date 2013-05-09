require 'wasabi/version'
require 'wasabi/document'
require 'wasabi/resolver'

class Wasabi

  XSD  = 'http://www.w3.org/2001/XMLSchema'
  WSDL = 'http://schemas.xmlsoap.org/wsdl/'

  SOAP_1_1 = 'http://schemas.xmlsoap.org/wsdl/soap/'
  SOAP_1_2 = 'http://schemas.xmlsoap.org/wsdl/soap12/'

  def initialize(wsdl, request = nil)
    resolver = Resolver.new(request)

    xml = resolver.resolve(wsdl)
    document = Nokogiri.XML(xml)

    @parser = Parser.new(document)
  end

  attr_reader :parser

  def service_name
    @parser.service_name
  end

  # TODO: move this to an operation.
  def endpoint
    @parser.endpoint
  end

  def target_namespace
    @parser.target_namespace
  end

  def namespaces
    @parser.namespaces
  end

  def schemas
    @parser.schemas
  end

  def operation(operation_name)
    @parser.operations[operation_name]
  end

end
