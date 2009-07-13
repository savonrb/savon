require "rubygems"
require "hpricot"
require "apricoteatsgorilla"

module Savon

  # Savon::Response represents the HTTP response.
  class Response

    # The HTTP or SOAP fault message.
    attr_reader :fault

    # The HTTP or SOAP fault code.
    attr_reader :fault_code

    # Initializer expects the HTTP response and checks for HTTP or SOAP faults.
    #
    # === Parameters
    #
    # * +response+ - The Net::HTTP response.
    def initialize(response)
      @response = response
      validate
    end

    # Returns true if the request was successful, false otherwise.
    def success?
      @fault_code.nil?
    end

    # Returns true if there was a HTTP or SOAP fault, false otherwise.
    def fault?
      !@fault_code.nil?
    end

    # Returns the SOAP response message as a Hash. Call with XPath expession
    # (Hpricot search) to define a custom +root_node+ to start parsing at.
    # Defaults to "//return". The root node will not be included in the Hash.
    #
    # === Parameters
    #
    # * +root_node+ - Optional. Custom root node to start parsing at.
    def to_hash(root_node = "//return")
      return nil if fault?
      ApricotEatsGorilla[@response.body, root_node]
    end

    # Returns the SOAP response message as a Savon::Mash object. Call with
    # XPath expession to define a custom +root_node+. Defaults to "//return".
    # The root node will not be included in the Mash object.
    #
    # === Parameters
    #
    # * +root_node+ - Optional. Custom root node to start parsing at.
    def to_mash(root_node = "//return")
      return nil if fault?
      hash = to_hash(root_node)
      Savon::Mash.new(hash)
    end

    # Returns the SOAP response XML.
    def to_s
      @response.body
    end

  private

    # Checks for HTTP and SOAP faults.
    def validate
      if @response.code.to_i >= 300
        @fault, @fault_code = @response.message, @response.code
      else
        fault = to_hash("//soap:Fault")
        @fault = fault[:faultstring] unless fault.nil?
        @fault_code = fault[:faultcode] unless fault.nil?
      end
    end

  end
end