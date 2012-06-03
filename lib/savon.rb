require "savon/version"
require "savon/config"
require "savon/logger"
require "savon/client"
require "savon/model"

module Savon
  extend self

  def client(*args)
    Client.new(*args)
  end

  def configure
    yield config
  end

  def config
    @config ||= Config.new.tap { |config|
      config.logger = Logger.new
      config.raise_errors = true
      config.soap_version = SOAP::DefaultVersion
    }
  end

  attr_writer :config

end
