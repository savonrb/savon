require "savon/core_ext/string"

module Savon
  module CoreExt
    module Symbol

      # Returns the Symbol as a lowerCamelCase String.
      def to_soap_key
        to_s.to_soap_key.lower_camelcase
      end

    end
  end
end

Symbol.send :include, Savon::CoreExt::Symbol
