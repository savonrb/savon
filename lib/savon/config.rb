require "savon/logger"
require "savon/null_logger"
require "savon/hooks/group"
require "savon/soap"

module Savon
  Config = Struct.new(:_logger, :pretty_print_xml, :raise_errors, :soap_version, :env_namespace, :soap_header) do

    def self.default
      config = new
      config._logger = Logger.new
      config.raise_errors = true
      config.soap_version = SOAP::DefaultVersion
      config
    end

    def logger=(logger)
      _logger.subject = logger
    end

    def log_level=(level)
      _logger.level = log_level
    end

    def log=(log)
      if log == true
        self._logger = Logger.new
      else
        self._logger = NullLogger.new
      end
    end

    def hooks
      @hooks ||= Hooks::Group.new
    end

    def clone
      config = super
      config.logger = config.logger.clone
      config
    end

  end
end
