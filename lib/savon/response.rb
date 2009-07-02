# -*- coding: utf-8 -*-
require 'rubygems'
require 'apricoteatsgorilla'

module Savon

  # Savon::Response represents the SOAP response and offers different methods
  # to handle the response.
  class Response

    # Initializer to set the SOAP response.
    def initialize(response)
      @response = response
    end

    # Returns the SOAP response message as a Hash. Call with XPath expession
    # (Hpricot search) as parameter to define a custom root node. The root node
    # itself will not be included in the Hash.
    def to_hash(root_node = "//return")
      ApricotEatsGorilla(@response.body, root_node)
    end

    # Returns the raw XML response.
    def to_s
      @response.body
    end

  end
end