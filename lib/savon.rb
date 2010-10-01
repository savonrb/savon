require "savon/global"
require "savon/client"

module Savon
  extend Global

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

  # Yields the <tt>Savon::Config</tt> class to a given +block+.
  def self.configure
    yield self if block_given?
  end

end
