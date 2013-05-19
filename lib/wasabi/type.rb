class Wasabi
  class Type

    class BaseType

      def initialize(node, schemas, schema = {})
        @node = node
        @schemas = schemas
        @schema = schema
      end

      attr_reader :node

      def [](key)
        @node[key]
      end

      def empty?
        children.empty? || children.first.empty?
      end

      def children
        @children ||= @node.element_children.map { |child| Type.build(child, @schemas, @schema) }
      end

      def child_elements(memo = [])
        children.each do |child|
          memo << child if child.kind_of? Element
          child.child_elements(memo)
        end
        memo
      end

    end

    class PrimaryType < BaseType

      def initialize(node, schemas, schema = {})
        super

        @namespace = schema[:target_namespace]
        @element_form_default = schema[:element_form_default]

        @name = node['name']
        @type = node['type']
        @form = node['form'] || 'unqualified'

        @namespaces = node.namespaces
      end

      attr_reader :name, :type, :namespace, :namespaces

      def qualify?
        @form == 'qualified' || @element_form_default == 'qualified'
      end

    end

    class SimpleType < PrimaryType

      def base
        child = @node.element_children.first
        child['base'] if child.name == 'restriction'
      end

    end

    class Element < PrimaryType

      def type
        return @type if @type

        simple_type = children.find { |child| child.kind_of? SimpleType }
        simple_type.base if simple_type
      end

    end

    class ComplexType < PrimaryType; end

    class Extension < BaseType

      def child_elements(memo = [])
        if @node['base']
          local, nsid = @node['base'].split(':').reverse
          namespace = @node.namespaces["xmlns:#{nsid}"]

          if complex_type = @schemas.complex_type(namespace, local)
            memo << complex_type
          elsif simple_type = @schemas.simple_type(namespace, local)
            memo << simple_type
          end
        end

        super
      end

    end

    class AnyType        < BaseType; end
    class ComplexContent < BaseType; end
    class Restriction    < BaseType; end
    class All            < BaseType; end
    class Sequence       < BaseType; end
    class Choice         < BaseType; end
    class Enumeration    < BaseType; end

    class SimpleContent < BaseType

      # stop searching for child elements
      def child_elements(memo = [])
        memo
      end

    end

    class Annotation < BaseType

      # stop searching for child elements
      def child_elements(memo = [])
        memo
      end

    end

    TYPE_MAPPING = {
      'element'        => Element,
      'complexType'    => ComplexType,
      'simpleType'     => SimpleType,
      'simpleContent'  => SimpleContent,
      'complexContent' => ComplexContent,
      'extension'      => Extension,
      'restriction'    => Restriction,
      'all'            => All,
      'sequence'       => Sequence,
      'choice'         => Choice,
      'enumeration'    => Enumeration,
      'annotation'     => Annotation
    }

    def self.build(node, schemas, schema = {})
      type_class(node.name).new(node, schemas, schema)
    end

    def self.type_class(type)
      TYPE_MAPPING.fetch(type, AnyType)
    end

  end
end
