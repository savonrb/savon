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

    def import(location)
      @import_locations = []

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

        @logger.info("Resolving XML schema import #{schema_location.inspect}.")

        import_document(schema_location) do |document|
          @schemas.push(document.schemas)
        end
      end
    end

    def absolute_url?(location)
      location =~ Resolver::URL_PATTERN
    end

  end
end
