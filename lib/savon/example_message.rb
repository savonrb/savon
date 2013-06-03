class Savon
  class ExampleMessage

    def initialize(parts)
      @parts = parts
    end

    def to_hash
      build(@parts)
    end

    private

    def build(elements)
      memo = {}

      elements.each do |element|
        name = element.name.to_sym

        case
        when element.simple_type?
          base_type_local = element.base_type.split(':').last
          base_type_local = [base_type_local] unless element.singular?
          memo[name] = base_type_local

        when element.complex_type?
          value = build(element.children)
          value = [value] unless element.singular?
          memo[name] = value

        end
      end

      memo
    end

  end
end
