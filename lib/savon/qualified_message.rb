require "gyoku"

module Savon
  class QualifiedMessage

    def initialize(types, used_namespaces)
      @types = types
      @used_namespaces = used_namespaces
    end

    def to_hash(hash, path)
      return unless hash
      return hash.map { |value| add_namespaces_to_body(value, path) } if hash.kind_of?(Array)
      return hash.to_s unless hash.kind_of? Hash

      hash.inject({}) do |newhash, (key, value)|
        camelcased_key = Gyoku::XMLKey.create(key).to_s
        newpath = path + [camelcased_key]

        if @used_namespaces[newpath]
          newhash.merge(
            "#{@used_namespaces[newpath]}:#{camelcased_key}" =>
              add_namespaces_to_body(value, @types[newpath] ? [@types[newpath]] : newpath)
          )
        else
          add_namespaces_to_values(value, path) if key == :order!
          newhash.merge(key => value)
        end
      end
    end

    private

    def add_namespaces_to_body(value, path)
      QualifiedMessage.new(@types, @used_namespaces).to_hash(value, path)
    end

    def add_namespaces_to_values(values, path)
      values.collect! { |value|
        camelcased_value = Gyoku::XMLKey.create(value)
        namespace_path = path + [camelcased_value.to_s]
        namespace = @used_namespaces[namespace_path]
        "#{namespace.blank? ? '' : namespace + ":"}#{camelcased_value}"
      }
    end

  end
end
