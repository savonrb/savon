module Savon

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

end

# standard libs
require "logger"
require "net/https"
require "base64"
require "digest/sha1"
require "rexml/document"

# gem dependencies
require "builder"
require "crack/xml"

# core files
require "savon/core_ext"
require "savon/wsse"
require "savon/soap"
require "savon/request"
require "savon/response"
require "savon/wsdl_stream"
require "savon/wsdl"
require "savon/client"
