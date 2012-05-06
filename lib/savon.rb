require "savon/version"
require "savon/config"
require "savon/client"
require "savon/model"

module Savon

  def self.configure
    yield config
  end

  def self.config
    @config ||= Config.new
  end

end
