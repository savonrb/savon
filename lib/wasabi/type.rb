class Wasabi
  class Type

    class BaseType

      def initialize(node, wsdl)
        @node = node
        @wsdl = wsdl

        @name = node['name']
        @type = node['type']
      end

      attr_reader :node, :wsdl, :name, :type

      def to_hash
        { :name => name, :type => type }
      end

    end

    class SimpleType < BaseType

      def type
        first_child = @node.element_children.first
        if first_child.name == 'restriction'
          first_child['base']
        end
      end

    end

    class LegacyType < BaseType

      def element_type
        @node.name
      end

      def children
        return @children if @children

        case element_type
        when 'element'
          first_child = @node.element_children.first

          if first_child && first_child.name == 'complexType'
            children = parse_complex_type first_child, @node['name'].to_s
          end
        when 'complexType'
          children = parse_complex_type @node, @node['name'].to_s
        end

        @children = children || []
      end

      private

      def parse_complex_type(complex_type, name)
        children = []

        complex_type.xpath("./xs:all/xs:element", 'xs' => Wasabi::XSD).each do |element|
          children << parse_element(element)
        end

        complex_type.xpath("./xs:sequence/xs:element", 'xs' => Wasabi::XSD).each do |element|
          children << parse_element(element)
        end

        complex_type.xpath("./xs:complexContent/xs:extension/xs:sequence/xs:element", 'xs' => Wasabi::XSD).each do |element|
          children << parse_element(element)
        end

        complex_type.xpath('./xs:complexContent/xs:extension[@base]', 'xs' => Wasabi::XSD).each do |extension|
          base = extension.attribute('base').value.match(/\w+$/).to_s
          base_type = @wsdl.schemas.types.fetch(base) { raise "expected to find extension base #{base} in types" }

          children += base_type.children
        end

        children
      end

      def parse_element(element)
        name = element['name']
        type = element['type']

        # anyType elements don't have a type attribute.
        # see email_validation.wsdl
        _, nsid = type && type.split(':').reverse

        if nsid
          namespace = find_namespace(nsid, element)
          simple_type = namespace == Wasabi::XSD
        else
          # assume that elements with a @type qname lacking an nsid to reference the xml schema.
          simple_type = true
        end

        form = element['form']

        max_occurs = element['maxOccurs'].to_s
        singular = max_occurs.empty? || max_occurs == '1'

        { :name => name, :type => type,
          :simple_type => simple_type, :form => form, :singular => singular }
      end

      def find_namespace(nsid, element)
        # look for the namespace in the global namespaces collection
        namespace = @wsdl.namespaces[nsid]

        # look for the namespace declaration on the element itself
        if element_namespace = element.namespaces["xmlns:#{nsid}"]
          namespace = element_namespace
          @wsdl.namespaces[nsid] = element_namespace
        end

        missing_namespace! nsid unless namespace
        namespace
      end

      def missing_namespace!(nsid)
        raise "Unable to find the namespace for #{nsid.inspect} in:\n" +
              @wsdl.namespaces.inspect
      end

    end

  end
end
