require 'builder'

class Savon
  class Message

    ATTRIBUTE_PREFIX = '_'

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
            build_simple_type_element(element, xml, tag, value)

          when element.complex_type?
            build_complex_type_element(element, xml, tag, value)

        end
      end
    end

    def build_simple_type_element(element, xml, tag, value)
      if element.singular?
        if value.kind_of? Array
          raise ArgumentError, "Unexpected Array for the #{tag.last.inspect} simple type"
        end
        if value.is_a? Hash
          attributes, value = extract_attributes(value)
          if attributes.empty? && tag[1].nil?
            t = xml.tag! *tag, {} do |b|
              build_from_hash(b, value, xml)
            end
          else
            xml.tag! *tag, value[tag[1]], attributes
          end
        else
          xml.tag! *tag, value
        end
      else
        unless value.kind_of? Array
          raise ArgumentError, "Expected an Array of values for the #{tag.last.inspect} simple type"
        end

        value.each do |val|
          xml.tag! *tag, val
        end
      end
    end

    # build_from_hash 'foo', {a: {b: c: 123}}, xml
    #
    # => <foo><a><b><c>123</c></b></a></foo>
    #
    def build_from_hash(b, value, xml)
      if value.is_a? Hash
        value.each do |k, v|
          b.tag! k, {} do |_b|
            build_from_hash(_b, v, xml)
          end
        end
      else
        b.text! value.to_s
      end
    end

    def build_complex_type_element(element, xml, tag, value)
      if element.singular?
        unless value.kind_of? Hash
          raise ArgumentError, "Expected a Hash for the #{tag.last.inspect} complex type"
        end

        build_complex_tag(element, tag, value, xml)
      else
        unless value.kind_of? Array
          raise ArgumentError, "Expected an Array of Hashes for the #{tag.last.inspect} complex type"
        end

        value.each do |val|
          build_complex_tag(element, tag, val, xml)
        end
      end
    end

    def build_complex_tag(element, tag, value, xml)
      attributes, value = extract_attributes(value)
      children = element.children

      if children.count > 0
        xml.tag! *tag, attributes do |xml|
          build_elements(children, value, xml)
        end
      elsif value
        if value.is_a? Hash
          if attributes.empty? && tag[1].nil?
            xml.tag! *tag, {} do |b|
              build_from_hash(b, value, xml)
            end
          else
            xml.tag! *tag, tag[1] ? value[tag[1]] : value, attributes
          end
        else
          xml.tag! *tag, value
        end
      else
        xml.tag! *tag, attributes
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

    def extract_attributes(hash)
      attributes = {}

      hash.dup.each do |k, v|
        next unless k.to_s[0, 1] == ATTRIBUTE_PREFIX

        attributes[k.to_s[1..-1]] = v
        hash.delete(k)
      end

      [attributes, hash]
    end

  end
end
