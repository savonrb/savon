require "builder"

require "savon"
require "savon/core_ext/object"
require "savon/core_ext/string"

module Savon
  module CoreExt
    module Hash

      # Returns a new Hash with +self+ and +other_hash+ merged recursively.
      # Modifies the receiver in place.
      def deep_merge!(other_hash)
        other_hash.each_pair do |k,v|
          tv = self[k]
          self[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? tv.deep_merge(v) : v
        end
        self
      end unless defined? deep_merge!

      # Returns the values from the soap:Body element or an empty Hash in case the soap:Body tag could
      # not be found.
      def find_soap_body
        envelope = self[keys.first] || {}
        body_key = envelope.keys.find { |key| /.+:Body/ =~ key } rescue nil
        body_key ? envelope[body_key].map_soap_response : {}
      end

      # Maps keys and values of a Hash created from SOAP response XML to more convenient Ruby Objects.
      def map_soap_response
        inject({}) do |hash, (key, value)|
          value = case value
            when ::Hash   then value["xsi:nil"] ? nil : value.map_soap_response
            when ::Array  then value.map { |val| val.map_soap_response rescue val }
            when ::String then value.map_soap_response
          end
          
          new_key = if Savon.strip_namespaces?
            key.strip_namespace.snakecase.to_sym
          else
            key.snakecase
          end
          
          if hash[new_key] # key already exists, value should be added as an Array
            hash[new_key] = [hash[new_key], value].flatten
            result = hash
          else
            result = hash.merge new_key => value
          end
          result
        end
      end

    end
  end
end

Hash.send :include, Savon::CoreExt::Hash
