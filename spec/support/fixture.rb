# frozen_string_literal: true
class Fixture

  TYPES = { :gzip => "gz", :response => "xml", :wsdl => "xml" }

  class << self

    def [](type, fixture)
      fixtures(type)[fixture] ||= read_file type, fixture
    end

    def full_hash(fixture)
      @full_hash ||= {}
      @full_hash[fixture] ||= nori.parse(response(fixture))[:envelope][:body]
    end

    TYPES.each do |type, ext|
      define_method(type) { |fixture| self[type, fixture] }
    end

  private

    def nori
      Nori.new(:strip_namespaces => true, :convert_tags_to => lambda { |tag| Savon::StringUtils.snakecase(tag).to_sym })
    end

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
