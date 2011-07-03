module Fixture

  def fixture(file)
    fixtures[file] ||= File.read File.expand_path("spec/fixtures/#{file}.xml")
  end

private

  def fixtures
    @fixtures ||= {}
  end

end
