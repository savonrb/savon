require "logger"

require "savon/config"
require "savon/core_ext"
require "savon/http"
require "savon/request"
require "savon/wsdl"
require "savon/service"

module Savon

  # The current version.
  VERSION = "0.5.0"

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

end
