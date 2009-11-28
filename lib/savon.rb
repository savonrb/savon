# stdlib
require "logger"
require "net/http"
require "net/https"
require "uri"
require "base64"
require "digest/sha1"
require "rexml/document"

# gems
require "builder"
require "crack/xml"

# savon
require "savon/core_ext"
require "savon/validation"
require "savon/wsse"
require "savon/soap"
require "savon/request"
require "savon/wsdl"
require "savon/client"

module Savon

  # Current version.
  VERSION = "0.5.0"

  # SOAP datetime format.
#  SOAPDateTimeFormat = "%Y-%m-%dT%H:%M:%S"

  # SOAP datetime Regexp.
#  SOAPDateTimeRegexp = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

end
