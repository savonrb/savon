require 'wasabi/param'

class Wasabi
  class ParamFactory

    def initialize(operation, wsdl)
      @operation = operation
      @wsdl = wsdl
    end

    def build
      case @operation.style
      when 'rpc'      then build_rpc_parts
      when 'document' then build_document_parts
      else                 raise 'Unable to determine the document style'
      end
    end

    private

    # spec: http://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383532
    def build_rpc_parts
      find_parts.map { |part| Param.new(nil, part[:name]) }
    end

    def build_document_parts
      find_parts.map { |part|
        element, nsid = find_element_and_nsid part[:element]
        Param.new(nsid, element.name)
      }
    end

    def find_element_and_nsid(name)
      local, nsid = name.split(':').reverse
      namespace = @wsdl.namespaces.fetch(nsid)

      element = @wsdl.schemas.element(namespace, local)
      raise "Unable to find element #{name.inspect}" unless element

      [element, nsid]
    end

    def find_parts
      input = @operation.port_type_operation.input
      message = find_message input[:message]

      message.parts
    end

    def find_message(name)
      local = name.split(':').last

      @wsdl.documents.messages.fetch(local) {
        raise "Unable to find message #{name.inspect}"
      }
    end

  end
end
