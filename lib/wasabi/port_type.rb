require 'wasabi/port_type_operation'

class Wasabi
  class PortType

    def initialize(port_type_node)
      @port_type_node = port_type_node
    end

    def name
      @port_type_node['name']
    end

    def operations
      @operations ||= operations!
    end

    def to_hash
      operations_hash = Hash[operations.map { |name, operation| [name, operation.to_hash] }]
      { :name => name, :operations => operations_hash }
    end

    private

    def operations!
      operations = {}

      @port_type_node.element_children.each do |operation_node|
        next unless operation_node.name == 'operation'

        operation_name = operation_node['name']
        operation = PortTypeOperation.new(operation_node)

        operations[operation_name] = operation
      end

      operations
    end

  end
end
