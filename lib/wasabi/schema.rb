require "wasabi/type"

class Wasabi
  class Schema

    CHILD_TYPES = %w[element complexType simpleType]

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

    # TODO: change the code to use elements, complex_types and simple_types
    #       instead of merging different kinds of elements for all schemas.
    def types
      @types ||= @elements.merge(@complex_types)
    end

    def to_hash
      {
        :target_namespace     => target_namespace,
        :element_form_default => element_form_default,
        :elements             => inspect_all(elements),
        :complex_types        => inspect_all(complex_types),
        :simple_types         => inspect_all(simple_types)
      }
    end

    private

    def parse_types
      @schema.element_children.each do |node|
        next unless CHILD_TYPES.include? node.name

        name = node['name']

        case node.name
        when 'element'     then @elements[name]      = Type::Element.new(node)
        when 'complexType' then @complex_types[name] = Type::ComplexType.new(node)
        when 'simpleType'  then @simple_types[name]  = Type::SimpleType.new(node)
        end
      end
    end

    def inspect_all(collection)
      Hash[collection.map { |name, element| [name, element.to_hash] }]
    end

  end
end
