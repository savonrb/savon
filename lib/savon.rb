require "savon/version"
require "savon/new_client"
require "savon/model"

module Savon

  def self.new_client(globals = {})
    NewClient.new(globals)
  end

end
