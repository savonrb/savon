RSpec::Matchers.define :have_children do |tags|
  match do |node|
    results = tags.map do |name, value|
      node.children.any? { |child| child.to_s == xml_nodes(name => value) }
    end
    !results.any? { |result| result == false }
  end

  failure_message_for_should do |actual|
    "expected that #{actual} includes #{xml_nodes(expected)}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} does not include #{xml_nodes(expected)}"
  end

  description do
    "include #{xml_nodes(expected)}"
  end

  def xml_nodes(tags)
    tags = tags.first if tags.kind_of?(Array)
    tags.map { |name, value| "<#{name}>#{value}</#{name}>" }.join(", ")
  end

end
