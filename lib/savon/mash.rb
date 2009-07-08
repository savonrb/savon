module Savon

  # Savon::Mash converts a given Hash into a Mash object.
  class Mash

    def initialize(hash)
      hash.each do |key,value|
        value = Savon::Mash.new(value) if value.is_a? Hash

        if value.is_a? Array
          value = value.map do |item|
            if item.is_a?(Hash) then Savon::Mash.new(item) else item end
          end
        end

        self.instance_variable_set("@#{key}", value)
        self.class.send(:define_method, key, proc { self.instance_variable_get("@#{key}") })
        self.class.send(:define_method, "#{key}=", proc { |value| self.instance_variable_set("@#{key}", value) })
      end
    end

  end

end