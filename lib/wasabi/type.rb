class Wasabi

  class SimpleType

    def initialize(node, parser)
      @node = node
      @parser = parser
    end

    def type
      first_child = @node.element_children.first
      if first_child.name == 'restriction'
        first_child['base']
      end
    end

  end

  class Type

    def initialize(node, parser)
      @node = node
      @parser = parser

      @name = node['name']
    end

    attr_reader :name

    def type
      @node.name
    end

    def children
      return @children if @children

      case type
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
        base_type = @parser.schemas.types.fetch(base) { raise "expected to find extension base #{base} in types" }

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
        namespace = @parser.namespaces.fetch(nsid)
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

  end

end
