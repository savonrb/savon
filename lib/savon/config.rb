require "savon/logger"
require "savon/hooks/group"
require "savon/soap"

module Savon
  Config = Struct.new(:logger, :raise_errors, :soap_version, :env_namespace, :soap_header) do

    def self.default
      config = new
      config.logger = Logger.new
      config.raise_errors = true
      config.soap_version = SOAP::DefaultVersion
      config
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
