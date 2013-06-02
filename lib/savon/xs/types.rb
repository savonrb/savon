class Savon
  class XS

    class BaseType

      def initialize(node, wsdl, schema = {})
        @node = node
        @wsdl = wsdl
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
        @children ||= @node.element_children.map { |child| XS.build(child, @wsdl, @schema) }
      end

      def collect_child_elements(memo = [])
        children.each do |child|
          if child.kind_of? Element
            memo << child
          else
            memo = child.collect_child_elements(memo)
          end
        end

        memo
      end

      def inspect
        attributes = @node.attributes.
          inject({}) { |memo, (k, attr)| memo[k.to_s] = attr.value; memo }.
          map { |i| "%s=\"%s\"" % i }.
          join(' ')
        "<%s %s>" % [self.class, attributes]
      end

    end

    class PrimaryType < BaseType

      def initialize(node, wsdl, schema = {})
        super

        @namespace = schema[:target_namespace]
        @element_form_default = schema[:element_form_default]

        @name = node['name']
        @form = node['form'] || 'unqualified'

        @namespaces = node.namespaces
      end

      attr_reader :name, :form, :namespace, :namespaces

      def form
        if @form == 'qualified' || @element_form_default == 'qualified'
          'qualified'
        else
          'unqualified'
        end
      end

    end

    class SimpleType < PrimaryType

      def base
        child = @node.element_children.first
        child['base'] if child.name == 'restriction'
      end

    end

    class Element < PrimaryType

      def initialize(node, wsdl, schema = {})
        super

        @type = node['type']
        @ref  = node['ref']
      end

      attr_reader :type, :ref

      def inline_type
        children.first
      end

    end

    class ComplexType < PrimaryType

      alias_method :elements, :collect_child_elements

      def id
        [namespace, name].join(':')
      end

    end

    class Extension < BaseType

      def collect_child_elements(memo = [])
        if @node['base']
          local, nsid = @node['base'].split(':').reverse
          namespace = @node.namespaces["xmlns:#{nsid}"]

          if complex_type = @wsdl.schemas.complex_type(namespace, local)
            memo += complex_type.elements
          else #if simple_type = @wsdl.schemas.simple_type(namespace, local)
            raise 'simple type extension?!'
            #memo << simple_type
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
      def collect_child_elements(memo = [])
        memo
      end

    end

    class Annotation < BaseType

      # stop searching for child elements
      def collect_child_elements(memo = [])
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

    def self.build(node, wsdl, schema = {})
      type_class(node.name).new(node, wsdl, schema)
    end

    def self.type_class(type)
      TYPE_MAPPING.fetch(type, AnyType)
    end

  end
end
