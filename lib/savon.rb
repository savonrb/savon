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

  # Yields the <tt>Savon::Config</tt> class to a given +block+.
  def self.configure
    yield self if block_given?
  end

end
