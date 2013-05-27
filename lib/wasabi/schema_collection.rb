class Wasabi
  class SchemaCollection
    include Enumerable

    def initialize
      @schemas = []
    end

    def <<(schema)
      @schemas << schema
    end

    def push(schemas)
      @schemas += schemas
    end

    def each(&block)
      @schemas.each(&block)
    end

    def element(namespace, name)
      find_by_namespace(namespace).elements[name]
    end

    def complex_type(namespace, name)
      find_by_namespace(namespace).complex_types[name]
    end

    def simple_type(namespace, name)
      find_by_namespace(namespace).simple_types[name]
    end

    # TODO: store by namespace instead?
    def find_by_namespace(namespace)
      find { |schema| schema.target_namespace == namespace }
    end

  end
end
