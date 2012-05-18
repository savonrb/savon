module Fixture

  def self.[](file)
    fixtures[file]
  end

  def self.[]=(file, value)
    fixtures[file] = value
  end

  def self.fixtures
    @fixtures ||= {}
  end

  def fixture(file, ext = :wsdl)
    Fixture[file] ||= File.read File.expand_path("spec/fixtures/#{file}.#{ext}")
  end

end
