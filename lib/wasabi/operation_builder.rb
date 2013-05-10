require 'wasabi/operation'

class Wasabi
  class OperationBuilder

    def initialize(documents)
      @documents = documents
    end

    def build
      operations = {}

      # for now we just find the first soap service and determine the soap version to use this way.
      # we need to somehow let people determine the service (by name?) and port (by soap version?) to use.
      soap_service, soap_version = find_soap_service

      soap_port = soap_service.find_port_by_type(soap_version)

      # TODO: store the endpoint with the operation
      #endpoint = soap_port.location

      binding = find_binding(soap_port)
      port_type = find_port_type(binding)

      binding.operations.each do |operation_name, binding_operation|
        port_type_operation = port_type.find_operation_by_name(operation_name)

        operation = Operation.new(operation_name, binding_operation, port_type_operation, @documents)
        operations[operation_name] = operation
      end

      operations
    end

    private

    def find_soap_service
      @documents.services.each do |name, service|
        soap_1_1_port = service.soap_1_1_port
        return [service, Wasabi::SOAP_1_1] if soap_1_1_port

        service.soap_1_2_port
        return [service, Wasabi::SOAP_1_2] if soap_1_2_port
      end

      raise 'Unable to find a SOAP service'
    end

    def find_binding(port)
      binding_name = port.binding.split(':').last

      @documents.bindings.fetch(binding_name) {
        raise "Unable to find binding #{binding_name.inspect} for port #{port.name.inspect}"
      }
    end

    def find_port_type(binding)
      port_type_name = binding.port_type.split(':').last

      @documents.port_types.fetch(port_type_name) {
        raise "Unable to find portType #{port_type_name.inspect} for binding #{binding.name.inspect}"
      }
    end

  end
end
