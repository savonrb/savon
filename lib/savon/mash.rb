module Savon

  # Savon::Mash converts a given Hash into an Object.
  class Mash

    # Loops through a given +hash+, stores each value in an instance variable
    # and creates getter and setter methods.
    #
    # === Parameters
    #
    # * +hash+ - The Hash to convert.
    def initialize(hash)
      hash.each do |key,value|
        value = Savon::Mash.new(value) if value.is_a? Hash

        if value.is_a? Array
          value = value.map do |item|
            if item.is_a?(Hash) then Savon::Mash.new(item) else item end
          end
        end

        set_instance_variable key, value
        define_reader key
        define_writer key
      end
    end

  private

    # Sets and instance variable with a given +name+ and +value+.
    #
    # === Parameters
    #
    # * +name+ - Name of the instance variable.
    # * +value+ - Value of the instance variable.
    def set_instance_variable(name, value)
      self.instance_variable_set("@#{name}", value)
    end

    # Defines a reader method for a given instance +variable+.
    #
    # === Parameters
    #
    # * +variable+ - Name of the instance variable.
    def define_reader(variable)
      method = proc { self.instance_variable_get("@#{variable}") }
      self.class.send(:define_method, variable, method)
    end

    # Defines a writer method for a given instance +variable+.
    #
    # === Parameters
    #
    # * +variable+ - Name of the instance variable.
    def define_writer(variable)
      method = proc { |value| self.instance_variable_set("@#{variable}", value) }
      self.class.send(:define_method, "#{variable}=", method)
    end

  end
end