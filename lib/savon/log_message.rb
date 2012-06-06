module Savon
  class LogMessage

    def initialize(message, filter, options = {})
      self.message     = message
      self.filter      = filter
      self.with_pretty = options[:pretty]
      self.with_filter = options[:filter]
    end

    attr_accessor :message, :filter, :with_pretty, :with_filter

    def filter?
      with_filter && filter.any?
    end

    def pretty?
      with_pretty
    end

    def to_s
      return message unless pretty? || filter?

      doc = Nokogiri::XML(message)
      doc = apply_filter(doc) if filter?
      doc.to_xml(pretty_options)
    end

    private

    def apply_filter(doc)
      return doc unless doc.errors.empty?

      filter.each do |fi|
        doc.xpath("//*[local-name()='#{fi}']").each { |node| node.content = "***FILTERED***" }
      end

      doc
    end

    def pretty_options
      return {} unless pretty?
      { :indent => 2 }
    end

  end
end
