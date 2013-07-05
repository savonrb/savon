class Savon
  class WSDL
    class Port

      def initialize(port_node, soap_node)
        @name     = port_node['name']
        @binding  = port_node['binding']

        @type     = soap_node.namespace.href
        @location = soap_node['location']
      end

      attr_reader :name, :binding, :type, :location

      def fetch_binding(documents)
        binding_local = @binding.split(':').last

        documents.bindings.fetch(binding_local) {
          raise "Unable to find binding #{binding_local.inspect} for port #{@name.inspect}"
        }
      end

      def to_hash
        { name => { type: type, location: location } }
      end

    end
  end
end
