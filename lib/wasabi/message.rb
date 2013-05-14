class Wasabi
  class Message

    def initialize(message_node)
      @message_node = message_node
    end

    def name
      @message_node['name']
    end

    def parts
      @parts ||= parts!
    end

    private

    def parts!
      parts = []

      @message_node.element_children.each do |part_node|
        next unless part_node.name == 'part'

        part = {}

        part[:name]    = part_node['name']
        part[:type]    = part_node['type']
        part[:element] = part_node['element']

        parts << part
      end

      parts
    end

  end
end
