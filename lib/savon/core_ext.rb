files = %w(object string symbol datetime hash uri net_http)
files.each { |file| require "savon/core_ext/#{file}" }