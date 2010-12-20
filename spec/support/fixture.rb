class Fixture

  TYPES = { :gzip => "gz", :response => "xml", :wsdl => "xml" }

  class << self

    def [](type, fixture)
      fixtures(type)[fixture] ||= read_file type, fixture
    end

    def response_hash(fixture)
      @response_hash ||= {}
      @response_hash[fixture] ||= Savon::SOAP::XML.to_hash response(fixture)
    end

    TYPES.each do |type, ext|
      define_method type do |fixture|
        self[type, fixture]
      end
    end

  private

    def fixtures(type)
      @fixtures ||= {}
      @fixtures[type] ||= {}
    end

    def read_file(type, fixture)
      path = File.expand_path "../../fixtures/#{type}/#{fixture}.#{TYPES[type]}", __FILE__
      raise ArgumentError, "Unable to load: #{path}" unless File.exist? path
      
      File.read path
    end

  end
end
