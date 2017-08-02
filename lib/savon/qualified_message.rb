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
      return hash.map { |value| to_hash(value, path) } if hash.kind_of?(Array)
      return hash.to_s unless hash.kind_of? Hash

      if hash[:order!] == :use_schema || @order_with_schema
        @order_with_schema = true
        ordered_keys = @used_namespaces.select { |t| t.first == path.first && t.length == 2 }.keys.collect { |k| k.last }
        hash[:order!] = ordered_keys
      end

      result = hash.inject({}) do |newhash, (key, value)|
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
      end

      update_order_keys(result)
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

    def update_order_keys(hash)
      return hash unless @order_with_schema

      order_keys = hash.delete(:order!)
      present_order_keys = order_keys & hash.keys
      hash[:order!] = present_order_keys + (hash.keys - present_order_keys)
      hash
    end
  end
end
