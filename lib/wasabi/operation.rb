class Wasabi
  class Operation

    def initialize(name, endpoint, binding_operation, port_type_operation, documents)
      @name = name
      @endpoint = endpoint
      @binding_operation = binding_operation
      @port_type_operation = port_type_operation

      @documents = documents
      parse_nsid_and_input
    end

    attr_reader :name, :endpoint, :binding_operation, :port_type_operation, :nsid, :input

    def soap_action
      @binding_operation.soap_action
    end

    private

    def parse_nsid_and_input
      input = @port_type_operation.input

      if input && message_name = input[:message]
        message = find_message(message_name)

        # TODO: support multiple parts
        first_part = get_first_part(message)

        if element_name = first_part[:element]
          @input, @nsid = element_name.split(':').reverse
        else
          @nsid = message_name.split(':').reverse[1]
          @input = @name
        end
      else
        raise "no portType input or input missing a message attribute:\n#{input.inspect}"
      end
    end

    def find_message(message_name)
      message_name = message_name.split(':').last

      @documents.messages.fetch(message_name) {
        raise "Unable to find message #{message_name.inspect}"
      }
    end

    def get_first_part(message)
      first_part = message.parts.first
      raise "no parts for message #{message_name.inspect}" unless first_part

      first_part
    end

  end
end
