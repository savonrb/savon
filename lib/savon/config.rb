require "logger"
require "nokogiri"
require "savon/soap"
require "savon/hooks/group"

module Savon
  class Config

    def initialize
      self.log = true
      self.logger = ::Logger.new STDOUT
      self.log_level = :debug
      self.log_filter = []
      self.raise_errors = true
      self.soap_version = SOAP::DefaultVersion
    end

    attr_accessor :log, :logger, :log_level, :log_filter, :raise_errors, :soap_version, :env_namespace, :soap_header

    alias log? log
    alias raise_errors? raise_errors

    def soap_version=(version)
      if version && !SOAP::Versions.include?(version)
        raise ArgumentError, "Invalid SOAP version: #{version}"
      end

      @soap_version = version
    end

    # Logs a given +message+. Optionally filtered if +xml+ is truthy.
    def log(message, xml = false)
      return unless log?
      message = filter_xml(message) if xml && !log_filter.empty?
      logger.send log_level, message
    end

    # Filters the given +xml+ based on log filter.
    def filter_xml(xml)
      doc = Nokogiri::XML(xml)
      return xml unless doc.errors.empty?

      log_filter.each do |filter|
        doc.xpath("//*[local-name()='#{filter}']").map { |node| node.content = "***FILTERED***" }
      end

      doc.root.to_s
    end

    # Returns the hooks.
    def hooks
      @hooks ||= Hooks::Group.new
    end

  end
end
