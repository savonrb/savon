require 'savon/element'

class Savon
  class WSDL
    class MessageBuilder

      def initialize(wsdl)
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
        type = find_type part[:type], part[:namespaces]

        element = Element.new
        element.name = part[:name]
        element.form = 'unqualified'

        handle_type(element, type)
        element
      end

      # Private: Expects a part with an @element attribute, resolves the element
      # and its type and returns an Element with that type.
      def build_element(part)
        local, namespace = expand_qname(part[:element], part[:namespaces])
        schema = @wsdl.schemas.find_by_namespace(namespace)
        raise "Unable to find schema for #{namespace.inspect}" unless schema

        xs_element = schema.elements.fetch(local)
        type = find_type_for_element(xs_element)

        element = Element.new
        element.name = xs_element.name
        element.form = 'qualified'
        element.namespace = namespace

        handle_type(element, type)
        element
      end

      def handle_type(element, type)
        case type
        when XS::ComplexType
          element.complex_type_id = type.id
          element.children = child_elements(element, type)
        when XS::SimpleType
          element.base_type = type.base
        when String
          element.base_type = type
        end
      end

      def child_elements(parent, type)
        type.elements.map { |child_element|
          el = Element.new
          el.parent = parent

          if child_element.ref
            child_element = find_element(child_element.ref, child_element.namespaces)
            el.form = 'qualified'
          else
            el.form = child_element.form
          end

          el.name = child_element.name
          el.namespace = child_element.namespace

          # prevent recursion
          if recursive_child_definition? parent, child_element
            el.recursive_type = child_element.type
          else
            el.recursive = false
            type = find_type_for_element(child_element)
            handle_type(el, type)
          end

          max_occurs = child_element['maxOccurs'].to_s
          el.singular = max_occurs.empty? || max_occurs == '1'

          el
        }
      end

      # Private: Accepts an Element and figures out if its type is already defined in this
      # elements (self) ancestors. Used to prevent recursive child element definitions.
      def recursive_child_definition?(parent, element)
        return false unless element.type

        local, namespace = expand_qname(element.type, element.namespaces)
        id = [namespace, local].join(':')

        current_parent = parent

        while current_parent
          return true if current_parent.complex_type_id == id
          current_parent = current_parent.parent
        end

        false
      end

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
  end
end
