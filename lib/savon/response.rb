require 'rubygems'
require 'hpricot'
require 'apricoteatsgorilla'

module Savon

  # Savon::Response represents the SOAP response and includes methods for
  # working with the raw XML, a Hash or a Savon::Mash object.
  class Response

    attr_reader :fault, :fault_code

    # Initializer to set the SOAP response.
    def initialize(response)
      @response = response
      validate
    end

    # Returns true if the request was successful, false otherwise.
    def success?
      @fault_code.nil?
    end

    # Returns true if the request was not successful, false otherwise.
    def fault?
      !@fault.nil?
    end

    # Returns the SOAP response message as a Hash. Call with XPath expession
    # as parameter to define a custom root node. The root node itself will not
    # be included in the Hash.
    def to_hash(root_node = "//return")
      return nil if fault?
      ApricotEatsGorilla[@response.body, root_node]
    end

    # Returns the SOAP response message as a Savon::Mash object. Call with
    # XPath expession as parameter to define a custom root node. The root node
    # itself will not be included in the Mash object.
    def to_mash(root_node = "//return")
      return nil if fault?
      hash = to_hash(root_node)
      Savon::Mash.new(hash)
    end

    # Returns the raw XML response.
    def to_s
      @response.body
    end

  private

    # Checks for and stores HTTP and SOAP-Fault errors.
    def validate
      if @response.code.to_i >= 300
        @fault = @response.message
        @fault_code = @response.code
      else
        fault = to_hash("//soap:Fault")
        @fault = fault[:faultstring] unless fault.nil?
        @fault_code = fault[:faultcode] unless fault.nil?
      end
    end

  end
end