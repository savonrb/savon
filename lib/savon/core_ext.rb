# core ext files
%w(object string symbol datetime hash uri net_http).each { |file| require "savon/core_ext/#{file}" }
