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

    # Logs a given +message+.
    def log(message)
      logger.send log_level, message if log?
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
      self.raise_errors = nil
      self.soap_version = nil
      self.env_namespace = nil
      self.soap_header = nil
    end

  end
end

