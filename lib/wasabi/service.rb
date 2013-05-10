require 'wasabi/port'

class Wasabi
  class Service

    def initialize(service_node)
      @service_node = service_node
    end

    def name
      @service_node['name']
    end

    def ports
      @ports ||= ports!
    end

    def find_port
      ports.each do |_, port|
        matches = yield port
        return port if matches
      end

      nil
    end

    def find_port_by_type(type)
      find_port { |port| port.type == type }
    end

    def soap_1_1_port
      find_port_by_type(Wasabi::SOAP_1_1)
    end

    def soap_1_2_port
      find_port_by_type(Wasabi::SOAP_1_2)
    end

    def to_hash
      ports_hash = Hash[ports.map { |name, port| [name, port.to_hash] }]
      { :name  => name, :ports => ports_hash }
    end

    private

    def ports!
      ports = {}

      @service_node.element_children.each do |port_node|
        next unless port_node.name == 'port'

        soap_node = port_node.element_children.find { |node|
          namespace = node.namespace.href

          soap_1_1 = namespace == Wasabi::SOAP_1_1
          soap_1_2 = namespace == Wasabi::SOAP_1_2
          address  = node.name == 'address'

          (soap_1_1 || soap_1_2) && address
        }

        next unless soap_node

        port_name = port_node['name']
        port = Port.new(port_node, soap_node)

        ports[port_name] = port
      end

      ports
    end

  end
end
