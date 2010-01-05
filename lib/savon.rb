module Savon

  # Supported SOAP versions.
  SOAPVersions = [1, 2]

  # SOAP xs:dateTime format.
  SOAPDateTimeFormat = "%Y-%m-%dT%H:%M:%S"

  # SOAP xs:dateTime Regexp.
  SOAPDateTimeRegexp = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

end

# standard libs
%w(logger net/https openssl base64 digest/sha1 rexml/document).each do |lib|
  require lib
end

# gems
require "rubygems"
%w(builder crack/xml).each do |gem|
  require gem
end

# core files
%w(core_ext wsse soap request response wsdl client).each do |file|
  require File.dirname(__FILE__) + "/savon/#{file}"
end
