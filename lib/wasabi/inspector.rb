class Wasabi
  class Inspector

    def initialize(wsdl)
      @wsdl = wsdl
    end

    def to_hash
      {
        :service_name     => @wsdl.service_name,
        :target_namespace => @wsdl.target_namespace,
        :namespaces       => @wsdl.namespaces,
        :schemas          => schemas,
        :messages         => messages,
        :bindings         => bindings,
        :port_types       => port_types,
        :services         => services
      }
    end

    private

    def schemas
      @wsdl.schemas.map(&:to_hash)
    end

    def messages
      inspect_all(@wsdl.documents.messages)
    end

    def bindings
      inspect_all(@wsdl.documents.bindings)
    end

    def port_types
      inspect_all(@wsdl.documents.port_types)
    end

    def services
      inspect_all(@wsdl.documents.services)
    end

    def inspect_all(collection)
      Hash[collection.map { |name, element| [name, element.to_hash] }]
    end

  end
end
