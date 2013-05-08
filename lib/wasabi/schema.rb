require "wasabi/type"

module Wasabi
  class Schema

    CHILD_TYPES = %w[element complexType simpleType]

    def initialize(schema, parser)
      @schema = schema

      @target_namespace     = @schema['targetNamespace']
      @element_form_default = @schema['elementFormDefault']

      # TODO: get rid of this dependency.
      @parser = parser

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

    private

    def parse_types
      @schema.element_children.each do |node|
        next unless CHILD_TYPES.include? node.name

        type_name = node['name']

        case node.name
        when 'element'
          type = Type.new(node, @parser)
          @elements[type_name] = type
        when 'complexType'
          type = Type.new(node, @parser)
          @complex_types[type_name] = type
        when 'simpleType'
          simple_type = SimpleType.new(node, @parser)
          @simple_types[type_name] = simple_type
        end
      end
    end

  end
end
