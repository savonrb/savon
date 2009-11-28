%w(logger net/http net/https uri base64 digest/sha1 rexml/document).each do |lib|
  require lib
end

%w(builder crack/xml).each do |gem|
  require gem
end

%w(core_ext validation wsse soap request wsdl client).each do |file|
  require "savon/#{file}"
end

module Savon

  # The current version.
  VERSION = "0.5.0"

  # SOAP datetime format.
  SOAPDateTimeFormat = "%Y-%m-%dT%H:%M:%S"

  # SOAP datetime Regexp.
  SOAPDateTimeRegexp = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

end