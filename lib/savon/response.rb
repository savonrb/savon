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
      ApricotEatsGorilla[@response.body, root_node]
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
end