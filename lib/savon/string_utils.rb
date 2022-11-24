# frozen_string_literal: true

module Savon
  module StringUtils
    def self.snakecase(inputstring)
      str = inputstring.dup
      str.gsub! /::/, '/'
      str.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
      str.gsub! /([a-z\d])([A-Z])/, '\1_\2'
      str.tr! ".", "_"
      str.tr! "-", "_"
      str.downcase!
      str
    end
  end
end

