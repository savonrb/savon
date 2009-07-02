require 'rubygems'
require 'test/unit'
require 'mocha'
require 'shoulda'
require "apricoteatsgorilla"

["service", "wsdl", "response"].each do |file|
  require File.join(File.dirname(__FILE__), "..", "lib", "savon", file)
end

require File.join(File.dirname(__FILE__), "factories", "wsdl")
require File.join(File.dirname(__FILE__), "fixtures", "soap_response")