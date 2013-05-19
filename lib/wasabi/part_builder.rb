require 'wasabi/part'

class Wasabi
  class PartBuilder

    def initialize(operation, wsdl)
      @operation = operation
      @wsdl = wsdl
    end

    def build(parts = input_parts)
      parts.map { |part|

        name = part[:name]
        type_qname = part[:type]
        element_qname = part[:element]

        if type_qname
          next unless qname? type_qname
          TypePart.new(name, type_qname)
        elsif element_qname
          next unless qname? element_qname
          ElementPart.new(name, element_qname)
        end

      }.compact
    end

    private

    def qname?(qname)
      qname.include? ':'
    end

    def input_parts
      input   = @operation.port_type_operation.input
      message = find_message input[:message]

      message.parts
    end

    def find_message(name)
      local = name.split(':').last

      @wsdl.documents.messages[local] or
        raise "Unable to find message #{name.inspect}"
    end

  end
end
