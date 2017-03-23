require "gyoku"

module Savon
  class QualifiedMessage

    def initialize(types, used_namespaces, key_converter)
      @types = types
      @used_namespaces = used_namespaces
      @key_converter = key_converter
    end

    def to_hash(hash, path)
      return hash unless hash
      return hash.map { |value| to_hash(value, array_path(path)) } if hash.kind_of?(Array)
      return hash.to_s unless hash.kind_of? Hash

      order(path, hash.inject({}) do |newhash, (key, value)|
        if key == :order!
          add_namespaces_to_values(value, path)
          newhash.merge(key => value)
        else
          translated_key = Gyoku.xml_tag(key, :key_converter => @key_converter).to_s
          translated_key << "!" if key[-1] == "!"
          newpath = path + [translated_key]

          if @used_namespaces[newpath]
            newhash.merge(
              "#{@used_namespaces[newpath]}:#{translated_key}" =>
                to_hash(value, @types[newpath] ? [@types[newpath]] : newpath)
            )
          else
            newhash.merge(translated_key => value)
          end
        end
      end)
    end

    private

    def add_namespaces_to_values(values, path)
      values.collect! { |value|
        camelcased_value = Gyoku.xml_tag(value, :key_converter => @key_converter)
        namespace_path = path + [camelcased_value.to_s]
        namespace = @used_namespaces[namespace_path]
        "#{namespace.blank? ? '' : namespace + ":"}#{camelcased_value}"
      }
    end

    def array_path(path)
      item_paths = @types.select{|t| t.first == path.first}
      item_paths.length == 1 ? [item_paths.values.first] : path
    end

    def order(path, hash)
      result = {}
      @types.select{|t| t.first == path.first}.keys.collect{|k| k.last}.each do |key|
        ns = @used_namespaces[[path.first, key]]
        ns_key = ns + ":" + key
        next unless hash.key?(ns_key)

        result[ns_key] = hash.delete(ns_key)
      end

      hash.each_pair{|k,v| result[k] = v}
      result
    end

  end
end
