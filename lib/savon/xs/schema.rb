require 'savon/xs/types'

class Savon
  class XS
    class Schema

      def initialize(schema, schemas)
        @schema = schema
        @schemas = schemas

        @target_namespace     = @schema['targetNamespace']
        @element_form_default = @schema['elementFormDefault'] || 'unqualified'

        @attributes       = {}
        @attribute_groups = {}
        @elements         = {}
        @complex_types    = {}
        @simple_types     = {}
        @imports          = {}

        parse
      end

      attr_accessor :target_namespace, :element_form_default, :imports,
                    :attributes, :attribute_groups, :elements, :complex_types, :simple_types

      def merge!(schema)
        return unless self.target_namespace == schema.target_namespace
        self.imports.update(schema.imports)
        self.attributes.update(schema.attributes)
        self.attribute_groups.update(schema.attribute_groups)
        self.elements.update(schema.elements)
        self.complex_types.update(schema.complex_types)
        self.simple_types.update(schema.simple_types)
      end

      private

      def parse
        schema = {
          :target_namespace => @target_namespace,
          :element_form_default => @element_form_default
        }

        @schema.element_children.each do |node|
          case node.name
          when 'attribute'      then store_element(@attributes, node, schema)
          when 'attributeGroup' then store_element(@attribute_groups, node, schema)
          when 'element'        then store_element(@elements, node, schema)
          when 'complexType'    then store_element(@complex_types, node, schema)
          when 'simpleType'     then store_element(@simple_types, node, schema)
          when 'import'         then store_import(node)
          when 'include'        then store_import(node)
          end
        end
      end

      def store_element(collection, node, schema)
        collection[node['name']] = XS.build(node, @schemas, schema)
      end

      def store_import(node)
        unless node['namespace'].nil?
          @imports[node['namespace']] = node['schemaLocation']
        else
          @imports[node.namespace] = node['schemaLocation']
        end
      end

    end
  end
end
