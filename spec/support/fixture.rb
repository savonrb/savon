module SpecSupport

  class Fixture

    def initialize(fixture)
      @fixture = fixture
    end

    attr_reader :fixture

    def path
      absolute_path = File.expand_path("spec/fixtures/#{fixture}")
      paths = Dir.glob("#{absolute_path}*")

      raise ArgumentError, "Multiple fixtures for #{path.inspect}" if paths.count > 1

      path = paths.first
      raise ArgumentError, "Unable to find fixture #{fixture.inspect}" unless path

      path
    end

    def read
      File.read(path)
    end

  end

  def fixture(*args)
    Fixture.new(*args)
  end

end
