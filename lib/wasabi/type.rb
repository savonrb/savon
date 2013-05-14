class Wasabi
  class Type

    class BaseType

      def initialize(node)
        @node = node

        @name = node['name']
        @type = node['type']

        @namespaces = @node.namespaces
      end

      attr_reader :node, :name, :type, :namespaces

      def [](key)
        @node[key]
      end

      def children
        @children ||= @node.element_children.map { |c| Type.build(c) }
      end

    end

    class SimpleType < BaseType

      def type
        child = @node.element_children.first
        child['base'] if child.name == 'restriction'
      end

    end

    class Element        < BaseType; end
    class ComplexType    < BaseType; end
    class SimpleType     < BaseType; end
    class ComplexContent < BaseType; end
    class Extension      < BaseType; end
    class Restriction    < BaseType; end
    class All            < BaseType; end
    class Sequence       < BaseType; end
    class Enumeration    < BaseType; end
    class Annotation     < BaseType; end

    TYPE_MAPPING = {
      'element'        => Element,
      'complexType'    => ComplexType,
      'simpleType'     => SimpleType,
      'complexContent' => ComplexContent,
      'extension'      => Extension,
      'restriction'    => Restriction,
      'all'            => All,
      'sequence'       => Sequence,
      'enumeration'    => Enumeration,
      'annotation'     => Annotation
    }

    def self.build(node)
      type_class(node.name).new(node)
    end

    def self.type_class(type)
      TYPE_MAPPING.fetch(type) { raise "No type mapping for #{type.inspect}" }
    end

  end
end
