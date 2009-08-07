%w(service wsdl response).each do |file|
  require File.join(File.dirname(__FILE__), "savon", file)
end