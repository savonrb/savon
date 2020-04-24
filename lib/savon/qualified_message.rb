# frozen_string_literal: true
require "gyoku"

module Savon
  class QualifiedMessage
    def initialize(types, used_namespaces, key_converter)
      @types           = types
      @used_namespaces = used_namespaces
      @key_converter   = key_converter
    end

    def to_hash(hash, path)
      return hash unless hash
      return hash.map { |value| to_hash(value, path) } if hash.is_a?(Array)
      return hash.to_s unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), newhash|
        case key
        when :order!
          newhash[key] = add_namespaces_to_values(value, path)
        when :attributes!, :content!
          newhash[key] = to_hash(value, path)
        else
          if key.to_s =~ /!$/
            newhash[key] = value
          else
            translated_key  = translate_tag(key)
            newkey          = add_namespaces_to_values(key, path).first
            newpath         = path + [translated_key]
            newpath         = @types[newpath].nil? ? newpath : [@types[newpath]]
            newhash[newkey] = to_hash(value, newpath)
          end
        end
        newhash
      end
    end

    private

    def translate_tag(key)
      Gyoku.xml_tag(key, :key_converter => @key_converter).to_s
    end

    def add_namespaces_to_values(values, path)
      Array(values).collect do |value|
        translated_value = translate_tag(value)
        namespace_path   = path + [translated_value]
        namespace        = @used_namespaces[namespace_path]
        namespace.blank? ? value : "#{namespace}:#{translated_value}"
      end
    end
  end
end
