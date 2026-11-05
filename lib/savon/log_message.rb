# frozen_string_literal: true

require "nokogiri"

module Savon
  class LogMessage
    MIME_HEADER_PREFIX = /\A\s*[A-Za-z0-9-]+:/

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

    # The index of the XML document in the message. Multipart messages have MIME
    # headers before the XML part, and these can contain '<' (Content-ID: <...>).
    # If the first '<' is on a header line, the document starts at the first '<'
    # after the next blank line. A '<' before any blank line that is not on a
    # header line belongs to the document itself (e.g. a declaration-less
    # envelope with blank lines inside it).
    #
    # A fixed set of searches, plus a loop that only advances forward past
    # nested header tags, so the search stays linear in the message size.
    # Log input is attacker-influenced on the response side, so logging must
    # never be a slow path.
    def xml_start(message)
      message.index("<?xml") || first_tag(message)
    end

    def first_tag(message)
      first = message.index("<")
      return first unless first && mime_header_line?(message, first)

      pos = first
      loop do
        blank_line = message.index(/\r?\n\r?\n/, pos)
        tag = blank_line && message.index("<", blank_line)
        return first unless tag
        return tag unless mime_header_line?(message, tag)

        pos = tag
      end
    end

    def mime_header_line?(message, index)
      line_start = (message.rindex("\n", index) || -1) + 1
      message[line_start...index].match?(MIME_HEADER_PREFIX)
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
