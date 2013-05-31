require 'builder'

class Savon
  class Body

    def initialize(envelope, parts)
      @logger = Logging.logger[self]

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
        name = element.name
        symbol_name = name.to_sym

        value = extract_value(name, symbol_name, message)

        if value == :unspecified
          @logger.debug("Skipping (optional?) element #{symbol_name.inspect} with no value.")
          next
        end

        tag = [symbol_name]

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

    # Private: extracts the value from the message by name or symbol_name.
    # Respects nil values and returns a special symbol for actual missing values.
    def extract_value(name, symbol_name, message)
      if message.include? name
        message[name]
      elsif message.include? symbol_name
        message[symbol_name]
      else
        :unspecified
      end
    end

  end
end
