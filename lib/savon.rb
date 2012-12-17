module Savon

  class Error < RuntimeError; end
  class InitializationError < Error; end
  class InvalidResponseError < Error; end

  def self.client(globals = {}, &block)
    Client.new(globals, &block)
  end

  def self.mocked?
    defined?(super) ? super : false
  end

end

require "savon/version"
require "savon/client"
require "savon/model"
