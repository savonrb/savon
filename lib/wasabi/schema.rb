require "wasabi/type"

module Wasabi
  class Schema

    CHILD_TYPES = %w[element complexType simpleType]

    def initialize(schema, parser)
      @schema = schema

      # TODO: get rid of this dependency.
      @parser = parser
      @namespaces = parser.namespaces

      @elements      = {}
      @complex_types = {}
      @simple_types  = {}

      parse_types
    end

    attr_accessor :elements, :complex_types, :simple_types

    # TODO: change the code to use elements, complex_types and simple_types
    #       instead of merging different kinds of elements for all schemas.
    def types
      @types ||= @elements.merge(@complex_types)
    end

    private

    def parse_types
      schema_namespace     = @schema['targetNamespace']
      element_form_default = @schema['elementFormDefault']
      namespaces_by_value  = @namespaces.invert

      raise 'schema does not define a targetNamespace' unless schema_namespace

      @schema.element_children.each do |node|
        next unless CHILD_TYPES.include? node.name

        nsid = namespaces_by_value[schema_namespace]
        type_name = node['name']

        case node.name
        when 'element'
          type = Type.new(@parser, schema_namespace, nsid, element_form_default, node)
          @elements[type_name] = type
        when 'complexType'
          type = Type.new(@parser, schema_namespace, nsid, element_form_default, node)
          @complex_types[type_name] = type
        when 'simpleType'
          simple_type = SimpleType.new(@parser, node)
          @simple_types[type_name] = simple_type
        end
      end
    end

  end
end
