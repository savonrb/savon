require "savon/global"
require "savon/client"

module Savon
  extend Global

  # Base class for Savon errors.
  class Error < RuntimeError; end

  # Raised in case of an HTTP error.
  class HTTPError < Error; end

  # Raised in case of a SOAP fault.
  class SOAPFault < Savon::Error; end

  # Yields this module to a given +block+. Please refer to the
  # <tt>Savon::Global</tt> module for configuration options.
  def self.configure
    yield self if block_given?
  end

end
