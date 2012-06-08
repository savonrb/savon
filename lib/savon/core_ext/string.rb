require "savon/soap"

module Savon
  module CoreExt
    module String

      def self.included(base)
        unless "savon".respond_to?(:snakecase)
          base.send(:include, Extension)
        end
      end

      module Extension
        def snakecase
          str = dup
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
  end
end

String.send :include, Savon::CoreExt::String
