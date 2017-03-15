class Savon
  class XS

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
        @children ||= @node.element_children.map { |child| XS.build(child, @schemas, @schema) }
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

      def collect_attributes(memo = [])
        children.each do |child|
          if child.kind_of? Attribute
            memo << child
          else
            memo = child.collect_attributes(memo)
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

      def initialize(node, schemas, schema = {})
        super

        @namespace = schema[:target_namespace]
        @element_form_default = schema[:element_form_default]

        @name = node['name']
        # Because you've overriden the form method, you don't need to set
        # unqualified as the default when no form is specified.
        #@form = node['form'] || 'unqualified'
        @form = node['form']

        @namespaces = node.namespaces
      end

      attr_reader :name, :form, :namespace, :namespaces

      def form
        if @form
            @form
        elsif @element_form_default == 'qualified'
          'qualified'
        else
          'unqualified'
        end
      end

    end

    class SimpleType < PrimaryType

      def base
        @node.element_children.each { |child|
          local = child.name.split(':').last
          return child['base'] if local == 'restriction'
        }
      end

    end

    class Element < PrimaryType

      def initialize(node, schemas, schema = {})
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
      alias_method :attributes, :collect_attributes

      def id
        [namespace, name].join(':')
      end

    end

    class Extension < BaseType

      def collect_child_elements(memo = [])
        if @node['base']
          local, nsid = @node['base'].split(':').reverse
          namespace = @node.namespaces["xmlns:#{nsid}"]

          if complex_type = @schemas.complex_type(namespace, local)
            memo += complex_type.elements

          # TODO: can we find a testcase for this?
          else #if simple_type = @schemas.simple_type(namespace, local)
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

    class Attribute < BaseType

      def initialize(node, schemas, schema = {})
        super

        @name = node['name']
        @type = node['type']
        @ref  = node['ref']

        @use     = node['use'] || 'optional'
        @default = node['default']
        @fixed   = node['fixed']

        @namespaces = node.namespaces
      end

      attr_reader :name, :type, :ref, :namespaces,
                  :use, :default, :fixed

      def inline_type
        children.first
      end

      # stop searching for child elements
      def collect_child_elements(memo = [])
        memo
      end

    end

    class AttributeGroup < BaseType

      alias_method :attributes, :collect_attributes

      def collect_attributes(memo = [])
        if @node['ref']
          local, nsid = @node['ref'].split(':').reverse
          namespace = @node.namespaces["xmlns:#{nsid}"]

          attribute_group = @schemas.attribute_group(namespace, local)
          memo += attribute_group.attributes
        else
          super
        end
      end
    end

    class SimpleContent < BaseType

      # stop searching for attributes
      def collect_attributes(memo = [])
        memo
      end

      # stop searching for child elements
      def collect_child_elements(memo = [])
        memo
      end

    end

    class Annotation < BaseType

      # stop searching for attributes
      def collect_attributes(memo = [])
        memo
      end

      # stop searching for child elements
      def collect_child_elements(memo = [])
        memo
      end

    end

    TYPE_MAPPING = {
      'attribute'      => Attribute,
      'attributeGroup' => AttributeGroup,
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
      type_class(node).new(node, schemas, schema)
    end

    def self.type_class(node)
      type = node.name.split(':').last

      if TYPE_MAPPING.include? type
        TYPE_MAPPING[type]
      else
        logger.debug("No type mapping for #{type.inspect}. ")
        AnyType
      end
    end

    def self.logger
      @logger ||= Logging.logger[self]
    end

  end
end
