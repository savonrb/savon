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

    def initialize(wsdl, parent, attributes)
      @wsdl = wsdl
      @parent = parent

      @name = attributes[:name]
      @type = attributes[:type]
      @namespace = attributes[:namespace]
      @form = attributes[:form]
      @singular = attributes[:singular]
      @recursive = attributes[:recursive] || false
    end

    attr_reader :parent, :name, :type, :namespace, :form

    def recursive?
      @recursive
    end

    def singular?
      @singular
    end

    def simple_type?
      !recursive? && !complex_type?
    end

    # Public: Returns the base type for a simpleType Element.
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

    # Public: Returns the child Elements for a complexType Element.
    def children
      @type.elements.map { |element|

        if element.ref
          element = find_element(element.ref, element.namespaces)
          form = 'qualified'
        else
          form = element.form
        end

        name = element.name
        namespace = element.namespace

        # prevent recursion
        if recursive_child_definition? element
          recursive = true
          type = element.type
        else
          recursive = false
          type = find_type_for_element(element)
        end

        max_occurs = element['maxOccurs'].to_s
        singular = max_occurs.empty? || max_occurs == '1'

        Element.new(@wsdl, self, name: name, type: type, namespace: namespace, form: form,
                                 singular: singular, recursive: recursive)
      }
    end

    def to_a(memo = [], stack = [])
      new_stack = stack + [name]
      attributes = { namespace: namespace, form: form, singular: singular? }

      if simple_type?
        attributes[:type] = base_type
        memo << [new_stack, attributes]

      elsif complex_type?
        memo << [new_stack, attributes]

        children.each do |child|
          child.to_a(memo, new_stack)
        end

      elsif recursive?
        attributes[:recursive_type] = type
        memo << [new_stack, attributes]

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

    private

    # Private: Accepts an Element and figures out if its type is already defined in this
    # elements (self) ancestors. Used to prevent recursive child element definitions.
    def recursive_child_definition?(element)
      return false unless element.type

      local, namespace = expand_qname(element.type, element.namespaces)
      current_parent = parent

      while current_parent
        if current_parent.type.name == local &&
          current_parent.type.namespace == namespace

          return true
        end

        current_parent = current_parent.parent
      end

      false
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

    # Private: Expects a part with a @type attribute, resolves the type
    # and returns an Element with that type.
    def build_type_element(part)
      name = part[:name]
      type = find_type part[:type], part[:namespaces]
      form = 'unqualified'

      Element.new(@wsdl, nil, name: name, type: type, form: form, singular: true)
    end

    # Private: Expects a part with an @element attribute, resolves the element
    # and its type and returns an Element with that type.
    def build_element(part)
      local, namespace = expand_qname(part[:element], part[:namespaces])
      schema = @wsdl.schemas.find_by_namespace(namespace)
      raise "Unable to find schema for #{namespace.inspect}" unless schema

      element = schema.elements.fetch(local)

      name = element.name
      type = find_type_for_element(element)
      form = 'qualified'

      Element.new(@wsdl, nil, name: name, type: type, namespace: namespace, form: form, singular: true)
    end

  end
end
