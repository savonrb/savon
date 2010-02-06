module Savon

  # Raised in case of an HTTP error.
  class HTTPError < StandardError; end

  # Raised in case of a SOAP fault.
  class SOAPFault < StandardError; end

end

# standard libs
%w(logger net/https base64 digest/sha1 rexml/document).each { |stdlib| require stdlib }

# gems
%w(builder crack/xml).each { |gem| require gem }

# core files
%w(core_ext wsse soap request response wsdl_stream wsdl client).each { |file| require "savon/#{file}" }
