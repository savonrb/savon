module Savon

  class Error < RuntimeError; end
  class InvalidResponseError < Error; end

  def self.client(globals = {})
    Client.new(globals)
  end

end

require "savon/version"
require "savon/client"
require "savon/model"
