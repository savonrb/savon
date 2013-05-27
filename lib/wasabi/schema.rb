require "wasabi/type"

class Wasabi
  class Schema

    def initialize(schema, wsdl)
      @schema = schema
      @wsdl = wsdl

      @target_namespace     = @schema['targetNamespace']
      @element_form_default = @schema['elementFormDefault'] || 'unqualified'

      @elements      = {}
      @complex_types = {}
      @simple_types  = {}
      @imports       = {}

      parse
    end

    attr_accessor :target_namespace, :element_form_default, :imports,
                  :elements, :complex_types, :simple_types

    private

    def parse
      schema = {
        :target_namespace => @target_namespace,
        :element_form_default => @element_form_default
      }

      @schema.element_children.each do |node|
        case node.name
        when 'element'     then @elements[node['name']]      = Type::Element.new(node, @wsdl, schema)
        when 'complexType' then @complex_types[node['name']] = Type::ComplexType.new(node, @wsdl, schema)
        when 'simpleType'  then @simple_types[node['name']]  = Type::SimpleType.new(node, @wsdl, schema)
        when 'import'      then @imports[node['namespace']]  = node['schemaLocation']
        end
      end
    end

  end
end
