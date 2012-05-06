require "logger"
require "nokogiri"
require "savon/soap"
require "savon/hooks/group"

module Savon
  class Config

    # Returns whether to log HTTP requests. Defaults to +true+.
    def log?
      @log != false
    end
    attr_writer :log

    # Returns the logger. Defaults to an instance of +Logger+ writing to STDOUT.
    def logger
      @logger ||= ::Logger.new STDOUT
    end
    attr_writer :logger

    # Returns the log level. Defaults to :debug.
    def log_level
      @log_level ||= :debug
    end
    attr_writer :log_level

    # Logs a given +message+. Optionally filtered if +xml+ is truthy.
    def log(message, xml = false)
      return unless log?
      message = filter_xml(message) if xml && !log_filter.empty?
      logger.send log_level, message
    end

    # Returns the log filter. Defaults to an empty Array.
    def log_filter
      @log_filter ||= []
    end
    attr_writer :log_filter

    # Filters the given +xml+ based on log filter.
    def filter_xml(xml)
      doc = Nokogiri::XML(xml)
      return xml unless doc.errors.empty?

      log_filter.each do |filter|
        doc.xpath("//*[local-name()='#{filter}']").map { |node| node.content = "***FILTERED***" }
      end

      doc.root.to_s
    end

    # Returns whether to raise errors. Defaults to +true+.
    def raise_errors?
      @raise_errors != false
    end
    attr_writer :raise_errors

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

  end
end
