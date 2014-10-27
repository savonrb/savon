class Savon
  class XS
    class SchemaCollection
      include Enumerable

      def initialize
        @schemas = []
      end

      def <<(schema)
        current_schema = find_by_namespace(schema.target_namespace)
        if current_schema.nil?
          @schemas << schema
        else
          current_schema.merge!(schema)
        end
      end

      def push(schemas)
        schemas.each do |schema|
          self << schema
        end
      end

      def each(&block)
        @schemas.each(&block)
      end

      def attribute(namespace, name)
        find_by_namespace(namespace).attributes[name]
      end

      def attribute_group(namespace, name)
        find_by_namespace(namespace).attribute_groups[name]
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
end
