require 'rubygems'
require 'test/unit'
require 'mocha'

["service", "response", "wsdl"].each do |file|
  require File.join(File.dirname(__FILE__), "..", "lib", "savon", file)
end
require File.join(File.dirname(__FILE__), "factories", "wsdl")