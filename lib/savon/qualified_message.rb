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

      if hash[:order!] == :use_schema || @order_with_schema
        @order_with_schema = true
        ordered_keys = @used_namespaces.select { |t| t.first == path.first && t.length == 2 }.keys.collect { |k| k.last }
        hash[:order!] = ordered_keys
      end

      result = hash.each_with_object({}) do |(key, value), newhash|
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
            newhash[newkey] = to_hash(value, @types[newpath] ? [@types[newpath]] : newpath)
          end
        end
        newhash
      end

      ordered_keys(result)
    end

    private

    def translate_tag(key)
      Gyoku.xml_tag(key, :key_converter => @key_converter).to_s
    end

    def add_namespaces_to_values(values, path)
      Array(values).collect do |value|
        translated_value = translate_tag(value)
        namespace_path   = path + [translated_value]
        namespace        = @used_namespaces[namespace_path] || ''
        namespace.empty? ? value : "#{namespace}:#{translated_value}"
      end
    end

    def ordered_keys(hash)
      return hash unless @order_with_schema

      if order_keys = hash.delete(:order!)
        present_order_keys = order_keys & hash.keys
        hash[:order!] = (present_order_keys + (hash.keys - present_order_keys)).select { |key| !key.to_s.end_with?('!') }
      end
      hash
    end
  end
end
