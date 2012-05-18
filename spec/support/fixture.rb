module Fixture

  def self.[](name)
    fixtures[name]
  end

  def self.[]=(name, value)
    fixtures[name] = value
  end

  def self.fixtures
    @fixtures ||= {}
  end

  def fixture(file, ext = :wsdl)
    filename = "#{file}.#{ext}"
    Fixture[filename] ||= File.read File.expand_path("spec/fixtures/#{filename}")
  end

end
