require "savon/hooks/group"

module Savon
  Config = Struct.new(:logger, :raise_errors, :soap_version, :env_namespace, :soap_header) do

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
