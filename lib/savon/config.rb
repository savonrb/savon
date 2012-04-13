require "logger"
require "savon/soap"
require "savon/hooks/group"

module Savon
  module Config

    # Sets whether to log HTTP requests.
    attr_writer :log

    # Returns whether to log HTTP requests. Defaults to +true+.
    def log?
      @log != false
    end

    # Sets the logger to use.
    attr_writer :logger

    # Returns the logger. Defaults to an instance of +Logger+ writing to STDOUT.
    def logger
      @logger ||= ::Logger.new STDOUT
    end

    # Sets the log level.
    attr_writer :log_level

    # Returns the log level. Defaults to :debug.
    def log_level
      @log_level ||= :debug
    end

    # Logs a given +message+. Optionally filtered if +xml+ is truthy.
    def log(message, message_type = false)
      return unless log?
      message = process_xml(message) if message_type = :xml
      logger.send log_level, message
    end

    # Returns the log filter. Defaults to an empty Array.
    def log_filter
      @log_filter ||= []
    end

    # Sets the log filter. Expects an Array.
    attr_writer :log_filter

    # TODO - filter_xml should be moved to the Savon class
    # Accepts a string, parses the string, filters it according to Savon.log_filter, then returns a string
    def filter_xml(xml)
      doc = Nokogiri::XML(xml)
      filter_xml_doc!(doc)
      doc.root.to_s
    end

    # Sets whether to raise HTTP errors and SOAP faults.
    attr_writer :raise_errors

    # Returns whether to raise errors. Defaults to +true+.
    def raise_errors?
      @raise_errors != false
    end

    # Sets the global SOAP version.
    def soap_version=(version)
      raise ArgumentError, "Invalid SOAP version: #{version}" if version && !SOAP::Versions.include?(version)
      @version = version
    end

    # Returns SOAP version. Defaults to +DefaultVersion+.
    def soap_version
      @version ||= SOAP::DefaultVersion
    end

    # Accessor for the global env_namespace.
    attr_accessor :env_namespace

    # Accessor for the global soap_header.
    attr_accessor :soap_header

    # Returns the hooks.
    def hooks
      @hooks ||= Hooks::Group.new
    end

    # Reset to default configuration.
    def reset_config!
      self.log = nil
      self.logger = nil
      self.log_level = nil
      self.log_filter = nil
      self.raise_errors = nil
      self.soap_version = nil
      self.env_namespace = nil
      self.soap_header = nil
      self.pretty_xml_logs = false
    end

    # When true, tidy all Savon xml log output
    attr_writer :pretty_xml_logs

    def pretty_xml_logs?
      @pretty_xml_logs ||= false
    end

    private

    # TODO - process_xml and filter_xml_doc! should be moved to the Savon class
    def process_xml(message)
      return message if log_filter.empty? && ! pretty_xml_logs?
      doc = Nokogiri::XML(message)
      filter_xml_doc!(doc) unless log_filter.empty?
      if pretty_xml_logs?
        doc.to_xml(:indent => 2)
      else
        # TODO - is there an option for Nokogiri::XML#to_xml to return the xml all as one line?
        doc.to_xml(:indent => 0).gsub("\n", "")
      end
    end

    def filter_xml_doc!(doc)
      return unless doc.errors.empty?

      log_filter.each do |filter|
        doc.xpath("//*[local-name()='#{filter}']").map { |node| node.content = "***FILTERED***" }
      end
      true
    end
  end
end

