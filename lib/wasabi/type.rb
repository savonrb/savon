module Wasabi

  class SimpleType

    def initialize(parser, node)
      @parser = parser
      @node = node
    end

    def type
      first_child = @node.element_children.first
      if first_child.name == 'restriction'
        first_child['base']
      end
    end

  end

  class Type

    def initialize(parser, namespace, nsid, element_form_default, node)
      @parser = parser
      @namespace = namespace
      @nsid = nsid
      @element_form_default = element_form_default
      @node = node

      @prefix, @name = qname(node['name'])
    end

    attr_reader :name, :prefix

    attr_reader :namespace

    def type
      @node.name
    end

    def qname(qname)
      local, nsid = qname.to_s.split(':').reverse
      nsid ||= @nsid

      [nsid, local]
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

      complex_type.xpath("./xs:all/xs:element", 'xs' => Parser::XSD).each do |element|
        children << parse_element(element)
      end

      complex_type.xpath("./xs:sequence/xs:element", 'xs' => Parser::XSD).each do |element|
        children << parse_element(element)
      end

      complex_type.xpath("./xs:complexContent/xs:extension/xs:sequence/xs:element", 'xs' => Parser::XSD).each do |element|
        children << parse_element(element)
      end

      complex_type.xpath('./xs:complexContent/xs:extension[@base]', 'xs' => Parser::XSD).each do |extension|
        base = extension.attribute('base').value.match(/\w+$/).to_s
        base_type = @parser.types.fetch(base) { raise "expected to find extension base #{base} in types" }

        children += base_type.children
      end

      children
    end

    def parse_element(element)
      name = element['name']
      type = element['type']

      local, nsid = type.split(':').reverse

      if nsid
        namespace = @parser.namespaces.fetch(nsid)
        simple_type = namespace == Parser::XSD
      else
        # assume that elements with a @type qname lacking an nsid to reference the xml schema.
        simple_type = true
      end

      form = element['form'] || @element_form_default
      qualified = form == 'qualified'

      max_occurs = element['maxOccurs'].to_s
      singular = max_occurs.empty? || max_occurs == '1'

      { :name => name, :type => type,
        :simple_type => simple_type, :qualified => qualified, :singular => singular }
    end

  end

end
