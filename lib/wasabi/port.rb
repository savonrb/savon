class Wasabi
  class Port

    def initialize(port_node, soap_node)
      @port_node = port_node
      @soap_node = soap_node
    end

    def name
      @port_node['name']
    end

    def binding
      @port_node['binding']
    end

    def type
      @soap_node.namespace.href
    end

    def location
      @soap_node['location']
    end

  end
end
