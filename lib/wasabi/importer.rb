require 'nokogiri'
require 'wasabi/document'
require 'wasabi/document_collection'
require 'wasabi/schema_collection'

class Wasabi
  class Importer

    def initialize(resolver, wsdl)
      @resolver = resolver
      @wsdl = wsdl
    end

    def import(location)
      documents = DocumentCollection.new
      schemas = SchemaCollection.new

      import_document(location) do |document|
        documents << document
        schemas.push(document.schemas)
      end

      # resolve xml schema imports
      import_schemas(schemas) do |schema_location|
        import_document(schema_location) do |document|
          schemas.push(document.schemas)
        end
      end

      [documents, schemas]
    end

    private

    def import_document(location, &block)
      xml = @resolver.resolve(location)
      document = Document.new Nokogiri.XML(xml), @wsdl

      block.call(document)

      # resolve wsdl imports
      document.imports.each do |import_location|
        import_document(import_location, &block)
      end
    end

    def import_schemas(schemas)
      schemas.each do |schema|
        schema.imports.each do |namespace, schema_location|
          next unless schema_location

          unless absolute_url? schema_location
            issue_schema_skipped_warning(schema_location)
            next
          end

          # TODO: also skip if the schema was already imported

          yield(schema_location)
        end
      end
    end

    def absolute_url?(location)
      location =~ Resolver::URL_PATTERN
    end

    def issue_schema_skipped_warning(location)
      warn "Skipping XML Schema import #{location.inspect}"
    end

  end
end
