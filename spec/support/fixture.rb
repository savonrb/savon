module SpecSupport

  class Fixture
    def self.[](name)
      fixtures[name]
    end

    def self.[]=(name, value)
      fixtures[name] = value
    end

    def self.fixtures
      @fixtures ||= {}
    end

    def initialize(file, ext = :wsdl)
      self.file = file
      self.ext = ext
    end

    attr_accessor :file, :ext

    def filename
      "#{file}.#{ext}"
    end

    def path
      File.expand_path("spec/fixtures/#{filename}")
    end

    def read
      Fixture[filename] ||= File.read(path)
    end
  end

  module Methods
    def fixture(*args)
      Fixture.new(*args)
    end
  end

end
