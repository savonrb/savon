require "savon/version"
require "savon/config"
require "savon/client"
require "savon/new_client"
require "savon/model"

module Savon
  extend self

  def client(*args, &block)
    Client.new(*args, &block)
  end

  def new_client(wsdl_locator, options = {})
    NewClient.new(wsdl_locator, options)
  end

  def configure
    yield config
  end

  def config
    @config ||= Config.default
  end

  attr_writer :config

end
