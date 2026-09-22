# frozen_string_literal: true

require "gyoku"

module Savon
  class QualifiedMessage
    def initialize(types, used_namespaces, key_converter)
      @types           = types
      @used_namespaces = used_namespaces
      @key_converter   = key_converter

      # Schema tables are keyed by exact element names, but message keys pass
      # through the key converter first (:entity_ids becomes "entityIds" while
      # the schema says "EntityIds"). Index both tables by downcased path so a
      # converted key can still find its schema entry. Exact matches always win.
      @types_index           = index_by_normalized_path(types)
      @used_namespaces_index = index_by_normalized_path(used_namespaces)
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
            type            = lookup(@types, @types_index, newpath)
            newhash[newkey] = to_hash(value, type ? [type] : newpath)
          end
        end
        newhash
      end
    end

    private

    def translate_tag(key)
      Gyoku.xml_tag(key, key_converter: @key_converter).to_s
    end

    def add_namespaces_to_values(values, path)
      Array(values).collect do |value|
        translated_value = translate_tag(value)
        namespace_path   = path + [translated_value]
        namespace        = lookup(@used_namespaces, @used_namespaces_index, namespace_path) || ''
        namespace.empty? ? value : "#{namespace}:#{translated_value}"
      end
    end

    # Finds the schema entry for a message path. Converted message keys rarely
    # match schema element names exactly ("entityIds" vs "EntityIds"), so fall
    # back to a case-insensitive match when the exact lookup misses.
    def lookup(table, index, path)
      return table[path] if table.key?(path)

      original = index[normalize_path(path)]
      original && table[original]
    end

    def normalize_path(path)
      path.map { |segment| segment.to_s.downcase }
    end

    def index_by_normalized_path(table)
      table.each_with_object({}) do |(path, _), memo|
        memo[normalize_path(path)] ||= path
      end
    end
  end
end
