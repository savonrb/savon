class Wasabi

  module SchemaFinder

    def find_type_for_element(element)
      if element.type
        find_type(element.type, element.namespaces)
      else
        element.inline_type
      end
    end

    def find_type(qname, namespaces)
      local, namespace = expand_qname(qname, namespaces)

      # assume built-in or unknown type for unqualified type qnames for now.
      # we could fallback to the element's default namespace. needs tests.
      return qname unless namespace

      schema = find_schema(namespace)

      # custom type
      if schema

        # complex type
        if complex_type = schema.complex_types[local]
          complex_type

        # simple type
        elsif simple_type = schema.simple_types[local]
          simple_type

        end

      # built-in or unknown type
      else
        qname

      end
    end

    def find_element(qname, namespaces)
      local, namespace = expand_qname(qname, namespaces)
      @wsdl.schemas.element(namespace, local)
    end

    def find_schema(namespace)
      @wsdl.schemas.find_by_namespace(namespace)
    end

    def split_qname(qname)
      qname.split(':').reverse
    end

    def expand_qname(qname, namespaces)
      local, nsid = split_qname(qname)
      namespace = namespaces["xmlns:#{nsid}"]

      [local, namespace]
    end

  end

  class Element
    include SchemaFinder

    def initialize(wsdl, attributes)
      @wsdl = wsdl

      @name = attributes[:name]
      @type = attributes[:type]
      @namespace = attributes[:namespace]
      @form = attributes[:form]
    end

    attr_reader :name, :namespace, :form

    def simple_type?
      !complex_type?
    end

    # Returns the base type for a simpleType Element.
    def base_type
      if @type.kind_of? Type::SimpleType
        @type.base
      elsif @type.kind_of? String
        @type
      end
    end

    def complex_type?
      @type.kind_of? Type::ComplexType
    end

    # Returns the child Elements for a complexType Element.
    def children
      @type.elements.map { |element|

        if element.ref
          ref_element = find_element(element.ref, element.namespaces)

          name = ref_element.name
          type = find_type_for_element(ref_element)
          namespace = ref_element.namespace
          form = 'qualified'
        else
          name = element.name
          type = find_type_for_element(element)
          namespace = element.namespace
          form = element.form
        end

        Element.new(@wsdl, name: name, type: type, namespace: namespace, form: form)
      }
    end

    def to_a(memo = [], stack = [])
      new_stack = stack + [name]

      if simple_type?
        memo << [new_stack, { namespace: namespace, form: form, type: base_type }]

      elsif complex_type?
        memo << [new_stack, { namespace: namespace, form: form }]

        children.each do |child|
          child.to_a(memo, new_stack)
        end
      end

      memo
    end

    def inspect
      inflection = { name: @name }

      if simple_type?
        inflection[:type] = 'type'
        inflection[:value] = base_type
      else
        inflection[:type] = 'children'
        inflection[:value] = children.map(&:name).join(', ')
      end

      %(<Element name="%{name}" %{type}="%{value}" />) % inflection
    end

  end

  class MessageBuilder
    include SchemaFinder

    def initialize(operation, wsdl)
      @operation = operation
      @wsdl = wsdl
    end

    def build(parts)
      parts.map { |part|
        case
        when part[:type]    then build_type_element(part)
        when part[:element] then build_element(part)
        end
      }.compact
    end

    private

    # Expects a part with a @type attribute, resolves the type
    # and returns an Element with that type.
    def build_type_element(part)
      name = part[:name]
      type = find_type part[:type], part[:namespaces]
      form = 'unqualified'

      Element.new(@wsdl, name: name, type: type, form: form)
    end

    # Expects a part with an @element attribute, resolves the element
    # and its type and returns an Element with that type.
    def build_element(part)
      local, namespace = expand_qname(part[:element], part[:namespaces])

      element = @wsdl.schemas.element(namespace, local)

      name = element.name
      type = find_type_for_element(element)
      form = 'qualified'

      Element.new(@wsdl, name: name, type: type, namespace: namespace, form: form)
    end

  end
end
