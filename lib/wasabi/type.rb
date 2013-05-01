module Wasabi
  class Type

    def initialize(parser, namespace, node)
      @parser    = parser
      @namespace = namespace
      @node      = node
    end

    attr_reader :namespace

    def children
      return @children if @children

      case @node.name
      when 'element'
        first_child = @node.element_children.first

        if first_child && first_child.name == 'complexType'
          children = process_type first_child, @node['name'].to_s
        end
      when 'complexType'
        children = process_type @node, @node['name'].to_s
      end

      @children = children || []
    end

    def process_type(type, name)
      children = []

      type.xpath("./xs:sequence/xs:element", 'xs' => Parser::XSD).each do |element|
        children << { :name => element["name"].to_s, :type => element["type"].to_s }
      end

      type.xpath("./xs:complexContent/xs:extension/xs:sequence/xs:element", 'xs' => Parser::XSD).each do |element|
        children << { :name => element["name"].to_s, :type => element["type"].to_s }
      end

      type.xpath('./xs:complexContent/xs:extension[@base]', 'xs' => Parser::XSD).each do |extension|
        base = extension.attribute('base').value.match(/\w+$/).to_s
        base_type = @parser.types.fetch(base) { raise "expected to find extension base #{base} in types" }

        children += base_type.children
      end

      children
    end

  end
end
