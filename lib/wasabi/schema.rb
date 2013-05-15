require "wasabi/type"

class Wasabi
  class Schema

    SCHEMA_TYPES = %w[element complexType simpleType]

    def initialize(schema, wsdl)
      @schema = schema
      @wsdl = wsdl

      @target_namespace     = @schema['targetNamespace']
      @element_form_default = @schema['elementFormDefault']

      @elements      = {}
      @complex_types = {}
      @simple_types  = {}

      parse_types
    end

    attr_accessor :target_namespace, :element_form_default,
                  :elements, :complex_types, :simple_types

    private

    def parse_types
      @schema.element_children.each do |node|
        next unless SCHEMA_TYPES.include? node.name

        name = node['name']

        case node.name
        when 'element'     then @elements[name]      = Type::Element.new(node)
        when 'complexType' then @complex_types[name] = Type::ComplexType.new(node)
        when 'simpleType'  then @simple_types[name]  = Type::SimpleType.new(node)
        end
      end
    end

  end
end
