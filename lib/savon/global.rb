require "logger"
require "savon/soap"

module Savon
  module Global

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

    # Logs a given +message+.
    def log(message)
      logger.send log_level, filtered(message) if log?
    end

    # Sets the log filter.
    attr_writer :log_filter

    # Returns the log filter. Defaults to blank.
    def log_filter
      @log_filter ||= ''
    end

    # Filters Message based on log filter
    def filtered(message)
      xml = Nokogiri::XML(message)
      return message if @log_filter.empty? || !xml.errors.empty?

      @log_filter.each do |filter|
        xml.xpath("//*[local-name()='#{filter}']").map { |node| node.content = '***FILTERED***' }
      end
      return xml.root.to_s
    end

    # Sets whether to raise HTTP errors and SOAP faults.
    attr_writer :raise_errors

    # Returns whether to raise errors. Defaults to +true+.
    def raise_errors?
      @raise_errors != false
    end

    # Sets the global SOAP version.
    def soap_version=(version)
      raise ArgumentError, "Invalid SOAP version: #{version}" unless SOAP::Versions.include? version
      @version = version
    end

    # Returns SOAP version. Defaults to +DefaultVersion+.
    def soap_version
      @version ||= SOAP::DefaultVersion
    end

    # Returns whether to strip namespaces in a SOAP response Hash.
    # Defaults to +true+.
    def strip_namespaces?
      Savon.deprecate("use Nori.strip_namespaces? instead of Savon.strip_namespaces?")
      Nori.strip_namespaces?
    end

    # Sets whether to strip namespaces in a SOAP response Hash.
    def strip_namespaces=(strip)
      Savon.deprecate("use Nori.strip_namespaces= instead of Savon.strip_namespaces=")
      Nori.strip_namespaces = strip
    end

    # Returns the global env_namespace.
    attr_reader :env_namespace

    # Sets the global env_namespace.
    attr_writer :env_namespace

    # Returns the global soap_header.
    attr_reader :soap_header

    # Sets the global soap_header.
    attr_writer :soap_header

    # Expects a +message+ and raises a warning if configured.
    def deprecate(message)
      warn("Deprecation: #{message}") if deprecate?
    end

    # Sets whether to warn about deprecations.
    def deprecate=(deprecate)
      @deprecate = deprecate
    end

    # Returns whether to warn about deprecation.
    def deprecate?
      @deprecate != false
    end

    # Reset to default configuration.
    def reset_config!
      self.log = true
      self.logger = ::Logger.new STDOUT
      self.log_level = :debug
      self.raise_errors = true
      self.soap_version = SOAP::DefaultVersion
      self.strip_namespaces = true
      self.env_namespace = nil
      self.soap_header = {}
      self.log_filter = ''
    end

  end
end

