module Savon
  class Inflector

    # Converts a given +string+ from lowerCamelCase/CamelCase to snake_case.
    def self.snake_case(string)
      string.to_s.
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

  end
end
