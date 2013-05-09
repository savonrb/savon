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

      import! [location] do |document|
        documents << document
        schemas.push(document.schemas)
      end

      [documents, schemas]
    end

    private

    def import!(locations, &block)
      locations.each do |location|
        xml = @resolver.resolve(location)
        document = Document.new Nokogiri.XML(xml), @wsdl

        block.call(document)

        import! document.imports, &block
      end
    end

  end
end
