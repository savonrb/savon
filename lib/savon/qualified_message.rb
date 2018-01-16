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
        namespace        = namespace_deep_look(namespace_path)
        namespace.blank? ? value : "#{namespace}:#{translated_value}"
      end
    end

    def namespace_deep_look(path)
      down_path = path.dup
      while !down_path.empty?
        namespace = namespace_by_path(down_path)
        return namespace if !namespace.nil?
        down_path.shift
      end
      up_path = path.dup
      while !up_path.empty?
        up_path.pop
        namespace = namespace_deep_look(up_path) if !up_path.empty?
        return namespace if !namespace.nil?
      end
    end

    def namespace_by_path(namespace_path)
      namespace_path_type = @types.find{|key,val| key.map{|e| e.to_s.underscore}  == namespace_path.map{|e| e.to_s.underscore}}
      namespace_path_type.nil? ? nil : @used_namespaces[namespace_path_type[0]]
    end
  end
end

