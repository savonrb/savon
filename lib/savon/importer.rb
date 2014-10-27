require 'nokogiri'
require 'savon/wsdl/document'

class Savon
  class Importer

    def initialize(resolver, documents, schemas)
      @logger = Logging.logger[self]

      @resolver = resolver
      @documents = documents
      @schemas = schemas
    end

    def import(location, root_relative = false)
      @import_locations = []
      @root_dir = File.dirname(location) if root_relative

      @logger.info("Resolving WSDL document #{location.inspect}.")
      import_document(location) do |document|
        @documents << document
        @schemas.push(document.schemas)
      end

    end

    private

    def import_document(location, &block)
      if @import_locations.include? location
        @logger.info("Skipping already imported location #{location.inspect}.")
        return
      end

      xml = @resolver.resolve(location)
      @import_locations << location

      document = WSDL::Document.new Nokogiri.XML(xml), @schemas
      block.call(document)

      document.schemas.each do |schema|
        import_schema(schema)
      end

      # resolve wsdl imports
      document.imports.each do |import_location|
        @logger.info("Resolving WSDL import #{import_location.inspect}.")
        import_document(import_location, &block)
      end
    end

    def import_schema(schema)
      schema.imports.each do |namespace, schema_location|
        next unless schema_location
        next if @schemas.include?(namespace)

        location = relative_to_root(schema_location)
        @logger.info("Resolving XML schema import #{location.inspect}.")

        import_document(location) do |document|
          @schemas.push(document.schemas)
        end
      end
    end

    def absolute_url?(location)
      location =~ Resolver::URL_PATTERN
    end

    def relative_to_root(location)
      return location unless @root_dir
      File.join(@root_dir, location)
    end
  end
end
