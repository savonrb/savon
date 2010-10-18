require "savon/version"
require "savon/global"
require "savon/client"

module Savon
  extend Global

  # Yields this module to a given +block+. Please refer to the
  # <tt>Savon::Global</tt> module for configuration options.
  def self.configure
    yield self if block_given?
  end

end
