RSpec::Matchers.define :have_children do |tags|
  match do |node|
    results = tags.map do |name, value|
      node.children.any? { |child| child.to_s == to_tags(name => value) }
    end
    !results.any? { |result| result == false }
  end

  failure_message_for_should do |actual|
    "expected that #{actual} includes #{to_tags(expected)}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} does not include #{to_tags(expected)}"
  end

  description do
    "include #{to_tags(expected)}"
  end

  def to_tags(tags)
    tags = tags.first if tags.kind_of?(Array)
    tags.map { |name, value| "<#{name}>#{value}</#{name}>" }.join(", ")
  end

end
