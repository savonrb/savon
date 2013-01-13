require "gyoku"

module Savon
  class QualifiedMessage

    def initialize(types, used_namespaces, key_converter)
      @types = types
      @used_namespaces = used_namespaces
      @key_converter = key_converter
    end

    def to_hash(hash, path)
      return unless hash
      return hash.map { |value| to_hash(value, path) } if hash.kind_of?(Array)
      return hash.to_s unless hash.kind_of? Hash

      hash.inject({}) do |newhash, (key, value)|
        translated_key = Gyoku.xml_tag(key, :key_converter => @key_converter).to_s
        newpath = path + [translated_key]

        if @used_namespaces[newpath]
          newhash.merge(
            "#{@used_namespaces[newpath]}:#{translated_key}" =>
              to_hash(value, @types[newpath] ? [@types[newpath]] : newpath)
          )
        else
          add_namespaces_to_values(value, path) if key == :order!
          newhash.merge(key => value)
        end
      end
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

  end
end
