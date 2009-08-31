module Savon

  # Raised by the <tt>on_http_error</tt> method in case of an HTTP error.
  # <tt>on_http_error</tt> may be overwritten to customize error handling.
  class HTTPError < StandardError; end

  # Raised by the <tt>on_soap_fault</tt> method in case of a SOAP fault.
  # <tt>on_soap_fault</tt> may be overwritten to customize error handling.
  class SOAPFault < StandardError; end

  # The logger to use.
  @@logger = nil

  # The log level to use.
  @@log_level = :debug

  # Sets the logger to use.
  def self.logger=(logger)
    @@logger = logger
  end

  # Sets the log level to use.
  def self.log_level=(log_level)
    @@log_level = log_level
  end

  # Logs a given +message+ using the +@@logger+ instance or yields the logger
  # to a given +block+ for logging multiple messages at once.
  def self.log(message = nil)
    if @@logger
      @@logger.send(@@log_level, message) if message
      yield @@logger if block_given?
    end
  end

end

%w(net/http uri rubygems hpricot apricoteatsgorilla).each do |gem|
  require gem
end

%w(service wsdl).each do |file|
  require File.join(File.dirname(__FILE__), "savon", file)
end
