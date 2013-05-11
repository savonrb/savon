class Wasabi
  class PortTypeOperation

    def initialize(operation_node)
      @operation_node = operation_node

      @name = operation_node['name']
      @input_node = find_node('input')
      @output_node = find_node('output')
    end

    attr_reader :name

    def input
      return @input if defined? @input
      @input = parse_node(@input_node)
    end

    def output
      return @output if defined? @output
      @output = parse_node(@output_node)
    end

    def to_hash
      { :name => name, :input => input, :output => output }
    end

    private

    def find_node(node_name)
      @operation_node.element_children.find { |node| node.name == node_name }
    end

    def parse_node(node)
      input = {}

      input[:name]    = node['name']
      input[:message] = node['message']

      input
    end

  end
end
