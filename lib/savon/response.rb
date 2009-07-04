# -*- coding: utf-8 -*-
require 'rubygems'
require 'apricoteatsgorilla'

module Savon

  # Savon::Response represents the SOAP response and includes methods for
  # working with the raw XML, a Hash or a Savon::Mash object.
  class Response

    # Initializer to set the SOAP response.
    def initialize(response)
      @response = response
    end

    # Returns the SOAP response message as a Hash. Call with XPath expession
    # as parameter to define a custom root node. The root node itself will not
    # be included in the Hash.
    def to_hash(root_node = "//return")
      ApricotEatsGorilla(@response.body, root_node)
    end

    # Returns the SOAP response message as a Savon::Mash object. Call with
    # XPath expession as parameter to define a custom root node. The root node
    # itself will not be included in the Mash object.
    def to_mash(root_node = "//return")
      hash = to_hash(root_node)
      Savon::Mash.new(hash)
    end

    # Returns the raw XML response.
    def to_s
      @response.body
    end

  end

  # Savon::Mash converts a given Hash into a Mash object.
  class Mash

    def initialize(hash)
      hash.each do |key,value|
        value = Savon::Mash.new value if value.is_a? Hash

        if value.is_a? Array
          value = value.map do |item|
            if item.is_a?(Hash) then Savon::Mash.new(item) else item end
          end
        end

        # Create and initialize an instance variable for this key/value pair
        self.instance_variable_set("@#{key}", value)
        # Create the getter that returns the instance variable
        self.class.send(:define_method, key, proc{self.instance_variable_get("@#{key}")})
        # Create the setter that sets the instance variable
        self.class.send(:define_method, "#{key}=", proc{|value| self.instance_variable_set("@#{key}", value)})
      end
    end

  end

end