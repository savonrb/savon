require "savon/version"
require "savon/client"
require "savon/model"

module Savon

  def self.client(globals = {})
    Client.new(globals)
  end

end
