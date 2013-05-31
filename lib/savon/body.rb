require 'builder'

class Savon
  class Body

    def initialize(envelope, parts)
      @envelope = envelope
      @parts = parts
    end

    def build(message)
      builder = Builder::XmlMarkup.new(indent: 2, margin: 2)

      build_elements(@parts, message.dup, builder)
      builder.target!
    end

    private

    def build_elements(elements, message, xml)
      elements.each do |element|
        tag = [element.name.to_sym]

        value = message.delete(element.name) ||
                message.delete(element.name.to_sym)

        # skip unspecified elements
        next unless value

        if element.form == 'qualified'
          nsid = @envelope.register_namespace(element.namespace)
          tag.unshift(nsid)
        end

        case
        when element.simple_type?
          if element.singular?
            # TODO: check for !array
            xml.tag! *tag, value
          else
            # TODO: check for array
            value.each do |val|
              xml.tag! *tag, val
            end
          end

        when element.complex_type?
          # TODO: check for arrays?!
          xml.tag! *tag do |xml|
            build_elements(element.children, value, xml)
          end

        end
      end
    end

  end
end
