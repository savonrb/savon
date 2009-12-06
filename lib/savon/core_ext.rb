%w(object string symbol datetime hash uri).each do |file|
  require "savon/core_ext/#{file}"
end
