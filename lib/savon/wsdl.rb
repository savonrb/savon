require 'savon/wsdl/operation'
require 'savon/wsdl/document_collection'
require 'savon/xs/schema_collection'
require 'savon/resolver'
require 'savon/importer'

class Savon
  class WSDL

    def initialize(wsdl, http, opts = {})
      @documents = WSDL::DocumentCollection.new
      @schemas = XS::SchemaCollection.new

      resolver = Resolver.new(http)
      importer = Importer.new(resolver, @documents, @schemas)
      importer.import(wsdl, opts[:root_relative] || false)
    end

    # Public: Returns the DocumentCollection.
    attr_reader :documents

    # Public: Returns the SchemaCollection.
    attr_reader :schemas

    # Public: Returns the name of the service.
    def service_name
      @documents.service_name
    end

    # Public: Returns a Hash of services and ports defined by the WSDL.
    def services
      @documents.services.values.inject({}) { |memo, service| memo.merge service.to_hash }
    end

    # Public: Returns an Hash of operation names to Operations by service and port name.
    def operations(service_name, port_name)
      verify_service_and_port_exist! service_name, port_name

      port = @documents.service_port(service_name, port_name)
      binding = port.fetch_binding(@documents)

      binding.operations.keys
    end

    # Public: Returns an Operation by service, port and operation name.
    def operation(service_name, port_name, operation_name)
      verify_operation_exists! service_name, port_name, operation_name

      port = @documents.service_port(service_name, port_name)
      endpoint = port.location

      binding = port.fetch_binding(@documents)
      binding_operation = binding.operations.fetch(operation_name)

      port_type = binding.fetch_port_type(@documents)
      port_type_operation = port_type.operations.fetch(operation_name)

      Operation.new(operation_name, endpoint, binding_operation, port_type_operation, self)
    end

    private

    # Private: Raises a useful error in case the operation does not exist.
    def verify_operation_exists!(service_name, port_name, operation_name)
      operations = operations(service_name, port_name)

      unless operations.include? operation_name
        raise ArgumentError, "Unknown operation #{operation_name.inspect} for " \
                             "service #{service_name.inspect} and port #{port_name.inspect}.\n" \
                             "You may want to try one of #{operations.inspect}."
      end
    end

    # Private: Raises a useful error in case the service or port does not exist.
    def verify_service_and_port_exist!(service_name, port_name)
      service = services[service_name]
      port = service[:ports][port_name] if service

      unless port
        raise ArgumentError, "Unknown service #{service_name.inspect} or port #{port_name.inspect}.\n" \
                             "Here is a list of known services and port:\n" + services.inspect
      end
    end

  end
end
