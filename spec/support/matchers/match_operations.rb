RSpec::Matchers.define :match_operations do |expected|
  match do |actual|
    actual.should have(expected.keys.size).items
    actual.keys.should include(*expected.keys)
    actual.each { |key, value| value.should == expected[key] }
  end
end
