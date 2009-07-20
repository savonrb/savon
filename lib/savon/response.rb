require "rubygems"
require "hpricot"
require "apricoteatsgorilla"

module Savon

  # Savon::Response validates and represents the HTTP/SOAP response.
  class Response

    # The core (inherited) methods to shadow.
    @@core_methods_to_shadow = [:id]

    # Returns the core methods to shadow.
    def self.core_methods_to_shadow
      @@core_methods_to_shadow
    end

    # Sets the core +methods+ to shadow.
    def self.core_methods_to_shadow=(methods)
      @@core_methods_to_shadow = methods if methods.kind_of? Array
    end

    # Returns the error code.
    attr_reader :error_code

    # Returns the error message.
    attr_reader :error_message

    # Initializer expects the +source+ to initialize from. Sets up the instance
    # from a given Net::HTTPResponse or a Hash depending on the given +source+.
    # May be called with a custom +root_node+ to start parsing the response at
    # in case the given +source+ is a Net::HTTPResponse.
    def initialize(source, root_node = nil)
      if source.kind_of? Hash
        initialize_from_hash source
      elsif source.respond_to? :body
        initialize_from_response source, root_node
      end
    end

    # Returns the value from a given +key+ from the response Hash.
    def [](key)
      value_from_hash(key)
    end

    # Returns +true+ in case the request was successful, +false+ otherwise
    # or +nil+ in case there's no request at all.
    def success?
      return nil unless @response
      @error_code.nil?
    end

    # Returns +false+ in case the request was not successful, +false+ otherwise
    # or +nil+ in case there's no request at all.
    def error?
      return nil unless @response
      !@error_code.nil?
    end

    # Returns the response Hash.
    def to_hash
      @hash
    end

    # Returns the response body in case there is any, +nil+ otherwise.
    def to_s
      return nil unless @response
      @response.body
    end

    # Intercepts calls to missing methods and returns values from the response
    # Hash in case the name of the missing +method+ matches one of its key.
    # Returns a new Savon::Response instance containing the value or returns
    # the actual value in case it is not a Hash.
    def method_missing(method, *args)
      value = value_from_hash method
      return value unless value.kind_of? Hash
      Savon::Response.new value
    end

  private

    # Initializes the instance from a Net::HTTPResponse. Validates the +response+
    # against HTTP errors and SOAP faults. Continues to translate the response
    # body into a Hash and delegates to initializing the instance from this Hash
    # in case the request was successful. An optional +root_node+ to start parsing
    # the response at might be supplied.
    def initialize_from_response(response, root_node = nil)
      @response = response
      validate_response

      if success?
        root_node ||= "//return"
        hash = ApricotEatsGorilla[@response.body, root_node]
        initialize_from_hash hash
      end
    end

    # Initializes the instance from a given +hash+.
    def initialize_from_hash(hash)
      @hash = hash
      shadow_core_methods
    end

    # Validates the response against HTTP errors and SOAP faults and sets the
    # +error_code+ and +error_message+ in case the request was not successful.
    def validate_response
      if @response.code.to_i >= 300
        @error_message = @response.message
        @error_code = @response.code
      else
        soap_fault = ApricotEatsGorilla[@response.body, "//soap:Fault"]
        unless soap_fault.nil?
          @error_message = soap_fault[:faultstring]
          @error_code = soap_fault[:faultcode]
        end
      end
    end

    # Dynamically defines methods from the Array of +@@core_methods_to_shadow+
    # to "shadow" inherited methods. Returns a value from the response Hash in
    # case a matching public method and a key from the Hash could be found.
    def shadow_core_methods
      @@core_methods_to_shadow.each do |method|
        if self.public_methods.include?(method.to_s) && value_from_hash(method)
          self.class.send(:define_method, method) { value_from_hash(method) }
        end
      end
    end

    # Returns a value from the response Hash. Tries to convert the given +key+
    # into a Symbol or a String to find the value to return.
    def value_from_hash(key)
      return nil unless @hash
      @hash[key.to_sym] || @hash[key.to_s]
    end

  end
end