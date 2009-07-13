require "rubygems"
require "hpricot"
require "apricoteatsgorilla"

module Savon

  # Savon::Response represents the HTTP response.
  class Response

    # The HTTP error or SOAP fault message.
    attr_reader :error_message

    # The HTTP error or SOAP fault code.
    attr_reader :error_code

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
      @error_code.nil?
    end

    # Returns true if there was a HTTP or SOAP fault, false otherwise.
    def error?
      !@error_code.nil?
    end

    # Returns the SOAP response message as a Hash. Call with XPath expession
    # (Hpricot search) to define a custom +root_node+ to start parsing at.
    # Defaults to "//return". The root node will not be included in the Hash.
    #
    # === Parameters
    #
    # * +root_node+ - Optional. Custom root node to start parsing at.
    def to_hash(root_node = "//return")
      return nil if error?
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
      return nil if error?
      hash = to_hash(root_node)
      Savon::Mash.new(hash)
    end

    # Returns the SOAP response XML.
    def to_s
      @response.body
    end

  private

    # Checks for HTTP errors and SOAP faults.
    def validate
      if @response.code.to_i >= 300
        @error_message, @error_code = @response.message, @response.code
      else
        soap_fault = to_hash("//soap:Fault")
        @error_message = soap_fault[:faultstring] unless soap_fault.nil?
        @error_code = soap_fault[:faultcode] unless soap_fault.nil?
      end
    end

  end
end