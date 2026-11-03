# frozen_string_literal: true

require "gyoku"

module Savon
  class QualifiedMessage
    # With qualify: false, keys and values are left as they are: only
    # order!: :use_schema applies, for schemas with unqualified elements.
    def initialize(types, used_namespaces, key_converter, qualify: true)
      @types           = types
      @used_namespaces = used_namespaces
      @key_converter   = key_converter
      @qualify         = qualify

      # Schema tables are keyed by exact element names, but message keys pass
      # through the key converter first (:entity_ids becomes "entityIds" while
      # the schema says "EntityIds"). Index both tables by downcased path so a
      # converted key can still find its schema entry. Exact matches always win.
      @types_index           = index_by_normalized_path(types)
      @used_namespaces_index = index_by_normalized_path(used_namespaces)
    end

    def to_hash(hash, path, schema_order: false)
      return hash unless hash
      return hash.map { |value| to_hash(value, path, schema_order: schema_order) } if hash.is_a?(Array)
      return scalar(hash) unless hash.is_a?(Hash)

      schema_order ||= self.class.order_option(hash) == :use_schema
      tags_by_key = {}

      newhash = hash.each_with_object({}) do |(key, value), newhash|
        case key
        when :order!, "order!"
          newhash[key] = add_namespaces_to_values(value, path) unless value == :use_schema
        when :attributes!, :content!
          newhash[key] = to_hash(value, path)
        else
          if key.to_s =~ /!$/
            newhash[key] = value
            tags_by_key[key] = translate_tag(key)
          else
            translated_key  = translate_tag(key)
            newkey          = add_namespaces_to_values(key, path).first
            newpath         = path + [translated_key]
            type            = lookup(@types, @types_index, newpath)
            newhash[newkey] = to_hash(value, type ? [type] : newpath, schema_order: schema_order)
            tags_by_key[newkey] = translated_key
          end
        end
        newhash
      end

      newhash[:order!] = order_by_schema(tags_by_key, path) if schema_order && order_by_schema?(hash)
      newhash
    end

    def self.order_option(hash)
      hash.key?(:order!) ? hash[:order!] : hash["order!"]
    end

    private

    # An explicit order! wins, and a hash with content! is a single element.
    def order_by_schema?(hash)
      [nil, :use_schema].include?(self.class.order_option(hash)) && !hash.key?(:content!)
    end

    def scalar(value)
      @qualify ? value.to_s : value
    end

    def translate_tag(key)
      Gyoku.xml_tag(key, key_converter: @key_converter).to_s
    end

    def add_namespaces_to_values(values, path)
      return Array(values) unless @qualify

      Array(values).collect do |value|
        translated_value = translate_tag(value)
        namespace_path   = path + [translated_value]
        namespace        = lookup(@used_namespaces, @used_namespaces_index, namespace_path) || ''
        namespace.empty? ? value : "#{namespace}:#{translated_value}"
      end
    end

    # Wasabi doesn't record elements inside an xs:choice or xs:group, so they
    # are unknown keys too: raise rather than guess where they go.
    def order_by_schema(tags_by_key, path)
      children = schema_children(path)
      if children.empty? && tags_by_key.any?
        raise Error, "order!: :use_schema found no schema sequence for #{path.join('/')}: " \
                     "give this level its own order! array"
      end

      position_by_tag = children.each_with_index.to_h
      unknown_tags = tags_by_key.values.reject { |tag| position_by_tag.key?(tag.downcase) }
      if unknown_tags.any?
        raise Error, "order!: :use_schema found no schema element for #{unknown_tags.join(', ')} in #{path.join('/')}: " \
                     "give this level its own order! array"
      end

      tags_by_key.keys.sort_by { |key| position_by_tag.fetch(tags_by_key[key].downcase) }
    end

    def schema_children(path)
      parent = normalize_path(path)
      (@schema_children ||= {})[parent] ||= @used_namespaces_index.keys.filter_map { |child|
        child.last if child.length == parent.length + 1 && child.first(parent.length) == parent
      }
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
