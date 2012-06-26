module Savon
  class LogMessage

    def initialize(message, filters, options = {})
      @message = message
      @filters = filters
      @options = options
    end

    def to_s
      return @message unless pretty? || filter?

      doc = Nokogiri.XML(@message)
      doc = apply_filter(doc) if filter?
      doc.to_xml(pretty_options)
    end

    private

    def filter?
      @options[:filter] && @filters.any?
    end

    def pretty?
      @options[:pretty]
    end

    def apply_filter(doc)
      return doc unless doc.errors.empty?

      @filters.each do |filter|
        apply_filter!(doc, filter)
      end

      doc
    end

    def apply_filter!(doc, filter)
      doc.xpath("//*[local-name()='#{filter}']").each do |node|
        node.content = "***FILTERED***"
      end
    end

    def pretty_options
      return {} unless pretty?
      { :indent => 2 }
    end

  end
end
