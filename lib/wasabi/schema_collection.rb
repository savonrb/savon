class Wasabi
  class SchemaCollection
    include Enumerable

    def initialize(schemas)
      @schemas = schemas
    end

    def each(&block)
      @schemas.each(&block)
    end

    def element(name)
      find_type { |schema| schema.elements[name] }
    end

    def complex_type(name)
      find_type { |schema| schema.complex_types[name] }
    end

    def simple_type(name)
      find_type { |schema| schema.simple_types[name] }
    end

    # TODO: change the code to use elements, complex_types and simple_types
    #       instead of merging different kinds of elements for all schemas.
    def types
      @types ||= inject({}) { |memo, schema| memo.merge(schema.types) }
    end

    private

    def find_type
      each do |schema|
        type = yield schema
        return type if type
      end
    end

  end
end
