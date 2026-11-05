# frozen_string_literal: true

require "nokogiri"

module Savon
  class LogMessage
    def initialize(message, filters = [], pretty_print = false)
      @message      = message
      @filters      = filters
      @pretty_print = pretty_print
    end

    def to_s
      message = @message
      begin
        message_is_xml = xml_start(message)
      rescue ArgumentError
        # The message encoding holds invalid bytes (e.g. a binary multipart
        # body mistagged as UTF-8): search the bytes instead of raising.
        message = message.b
        message_is_xml = xml_start(message)
      end
      has_filters    = @filters.any?
      pretty_print   = @pretty_print

      return @message unless message_is_xml
      return @message unless has_filters || pretty_print

      # The message may be multipart, cut off extra lines before open tag
      # and stop at the next MIME boundary, so the attachments that follow the
      # XML part do not make the document invalid.
      xml_end = message.index(/\r?\n--/, message_is_xml) || message.length
      document = Nokogiri.XML(message[message_is_xml...xml_end])
      document = apply_filter(document) if has_filters
      document.to_xml(nokogiri_options)
    end

    private

    # The index of the XML document in the message. A multipart message has
    # MIME headers (e.g. Content-ID: <...>) before the XML part, so prefer an
    # XML declaration, then the first tag after a blank line.
    def xml_start(message)
      message.index("<?xml") || message.index(/(?<=\r\n\r\n|\n\n)\s*\K</) || message.index("<")
    end

    def apply_filter(document)
      return document unless document.errors.empty?

      @filters.each do |filter|
        apply_filter! document, filter
      end

      document
    end

    def apply_filter!(document, filter)
      if filter.instance_of? Proc
        filter.call document
      else
        document.xpath("//*[local-name()='#{filter}']").each do |node|
          node.content = "***FILTERED***"
        end
      end
    end

    def nokogiri_options
      @pretty_print ? { indent: 2 } : { save_with: Nokogiri::XML::Node::SaveOptions::AS_XML }
    end
  end
end
