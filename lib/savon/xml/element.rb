class Savon
  class XML
    class Element

      def initialize
        @children   = []
        @attributes = {}
        @recursive  = false
        @singular   = true
      end

      attr_accessor :parent, :name, :namespace, :form

      # Public: Whether this element is a simple type.
      def simple_type?
        !!base_type
      end

      # Public: Whether this element is a complex type.
      def complex_type?
        !simple_type?
      end

      # Public: The base name for a simple type element.
      attr_accessor :base_type

      # Public: Accessor for whether this is a single element.
      attr_accessor :singular
      alias_method :singular?, :singular

      # Public: Whether or not this element's type is defined recursively,
      # meaning one of this element's parents is of the same type as this element.
      def recursive?
        !!recursive_type
      end

      # Public: The name of the recursive type definition if any.
      attr_accessor :recursive_type

      # Private: The complex type id for this element to track recursive type definitions.
      attr_accessor :complex_type_id

      # Public: The child elements.
      attr_accessor :children

      # Public: The attributes.
      attr_accessor :attributes

      # Public: Returns this element and its children as an Array of Hashes for inspection.
      def to_a(memo = [], stack = [])
        new_stack = stack + [name]
        data = { namespace: namespace, form: form, singular: singular? }

        unless attributes.empty?
          data[:attributes] = attributes.each_with_object({}) do |attribute, memo|
            memo[attribute.name] = { optional: attribute.optional? }
          end
        end

        if recursive?
          data[:recursive_type] = recursive_type
          memo << [new_stack, data]

        elsif simple_type?
          data[:type] = base_type
          memo << [new_stack, data]

        elsif complex_type?
          memo << [new_stack, data]

          children.each do |child|
            child.to_a(memo, new_stack)
          end

        end

        memo
      end

    end
  end
end
