require "savon/version"
require "savon/config"
require "savon/client"
require "savon/model"

module Savon
  extend Config

  # Yields this module to a given +block+. Please refer to the
  # <tt>Savon::Config</tt> module for configuration options.
  def self.configure
    yield self if block_given?
  end

end
