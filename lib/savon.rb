require "savon/config"
require "savon/core_ext"
require "savon/wsse"
require "savon/http"
require "savon/request"
require "savon/wsdl"
require "savon/service"

module Savon

  # The current version.
  VERSION = "0.5.0"

  SOAPDateTimeFormat = "%Y-%m-%dT%H:%M:%S"

  SOAPDateTimeRegexp = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

end
