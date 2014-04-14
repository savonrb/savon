require "nokogiri"

module Savon
  class LogMessage

    def initialize(message, filters = [], pretty_print = false)
      @message      = message
      @filters      = filters
      @pretty_print = pretty_print
    end

    def to_s
      message_is_xml = @message =~ /^</
      has_filters    = @filters.any?
      pretty_print   = @pretty_print

      return @message unless message_is_xml
      return @message unless has_filters || pretty_print

      document = Nokogiri.XML(@message)
      document = apply_filter(document) if has_filters
      document.to_xml(nokogiri_options)
    end

    private

    def apply_filter(document)
      return document unless document.errors.empty?

      @filters.each do |filter|
        apply_filter! document, filter
      end

      document
    end

    def apply_filter!(document, filter)
      document.xpath("//*[local-name()='#{filter}']").each do |node|
        node.content = "***FILTERED***"
      end
    end

    def nokogiri_options
      @pretty_print ? { :indent => 2 } : {}
    end

  end
end
