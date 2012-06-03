require "logger"
require "nokogiri"

module Savon
  class Logger

    def log(message)
      subject.send(level, message)
    end

    def log_filtered(message)
      if filter.empty?
        log(message)
      else
        log filter_xml(message)
      end
    end

    attr_writer :subject, :level, :filter

    def subject
      @subject ||= ::Logger.new(STDOUT)
    end

    def level
      @level ||= :debug
    end

    def filter
      @filter ||= []
    end

  private

    def filter_xml(xml)
      doc = Nokogiri::XML(xml)
      return xml unless doc.errors.empty?

      filter.each do |fi|
        doc.xpath("//*[local-name()='#{fi}']").each { |node| node.content = "***FILTERED***" }
      end

      doc.root.to_s
    end

  end
end
