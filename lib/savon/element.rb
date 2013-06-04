class Savon
  class Element

    def initialize
      @children   = []
      @attributes = {}
      @recursive  = false
      @singular   = true
    end

    attr_accessor :parent, :name, :form, :namespace, :singular, :recursive,
                  :base_type, :children, :complex_type_id, :recursive_type,
                  :attributes

    alias_method :singular?, :singular

    def recursive?
      !!recursive_type
    end

    def simple_type?
      !!base_type
    end

    def complex_type?
      !simple_type?
    end

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
