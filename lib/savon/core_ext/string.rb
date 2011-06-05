require "savon/soap"

module Savon
  module CoreExt
    module String

      # Returns the String in snake_case.
      def snakecase
        str = dup
        str.gsub! /::/, '/'
        str.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
        str.gsub! /([a-z\d])([A-Z])/, '\1_\2'
        str.tr! ".", "_"
        str.tr! "-", "_"
        str.downcase!
        str
      end unless method_defined?(:snakecase)

      # Returns the String in lowerCamelCase.
      def lower_camelcase
        str = dup
        str.gsub!(/\/(.?)/) { "::#{$1.upcase}" }
        str.gsub!(/(?:_+|-+)([a-z])/) { $1.upcase }
        str.gsub!(/(\A|\s)([A-Z])/) { $1 + $2.downcase }
        str
      end

      # Returns whether the String starts with a given +prefix+.
      def starts_with?(prefix)
        prefix = prefix.to_s
        self[0, prefix.length] == prefix
      end unless defined? starts_with?

    end
  end
end

String.send :include, Savon::CoreExt::String
