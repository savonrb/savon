require "savon/version"
require "savon/config"
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
    @config ||= Config.default
  end

  attr_writer :config

end
