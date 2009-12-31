%w(object string symbol datetime hash uri).each do |file|
  require File.dirname(__FILE__) + "/core_ext/#{file}"
end
