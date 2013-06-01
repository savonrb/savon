class Wasabi
  class Element

    def initialize
      @children  = []
      @recursive = false
      @singular  = true
    end

    attr_accessor :parent, :name, :form, :namespace, :singular, :recursive,
                  :base_type, :children, :complex_type_id, :recursive_type

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
      attributes = { namespace: namespace, form: form, singular: singular? }

      if recursive?
        attributes[:recursive_type] = recursive_type
        memo << [new_stack, attributes]

      elsif simple_type?
        attributes[:type] = base_type
        memo << [new_stack, attributes]

      elsif complex_type?
        memo << [new_stack, attributes]

        children.each do |child|
          child.to_a(memo, new_stack)
        end

      end

      memo
    end

  end
end
