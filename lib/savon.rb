module Savon

  # Supported SOAP versions.
  SOAPVersions = [1, 2]

  # SOAP xs:dateTime format.
  SOAPDateTimeFormat = "%Y-%m-%dT%H:%M:%SZ"

  # SOAP xs:dateTime Regexp.
  SOAPDateTimeRegexp = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

end

# standard libs
stdlibs = %w(logger net/https openssl base64 digest/sha1 rexml/document)
stdlibs.each { |stdlib| require stdlib }

# gems
gems = %w(builder crack/xml)
gems.each { |gem| require gem }

# core files
files = %w(core_ext wsse soap request response wsdl_stream wsdl client)
files.each { |file| require "savon/#{file}" }