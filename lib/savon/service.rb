# -*- coding: utf-8 -*-
require 'rubygems'
require 'net/http'
require 'uri'
require 'apricoteatsgorilla'

module Savon

  # Savon::Service is the SOAP client implementation.
  #
  # Instantiate a new Savon::Service object and pass in the WSDL of the service
  # you would like to work with. Then simply call the SOAP service method on your
  # instance and pass in a Hash of options you would like to send.
  #
  # Example:
  #   proxy = Savon::Service.new "http://example.com/ExampleService?wsdl"
  #   response = proxy.findExampleById(:id => "123")
  #
  # Get the raw SOAP response XML:
  #   response.to_s
  #
  # Get the SOAP response as a Hash:
  #   response.to_hash
  class Service

    # Sets the HTTP connection instance.
    attr_writer :http

    # Initializer to set the endpoint URI.
    def initialize(endpoint)
      @uri = URI(endpoint)
    end

    # Returns an Wsdl object instance.
    def wsdl
      @wsdl = Savon::Wsdl.new(@uri, http) if @wsdl.nil?
      @wsdl
    end

  private

    # Sets up the request headers and body, makes the request and returns a
    # Savon::Response object.
    def call_service
      headers = { 'Content-Type' => 'text/xml; charset=utf-8', 'SOAPAction' => @action }
      body = ApricotEatsGorilla.soap_envelope("wsdl" => wsdl.namespace_uri) do
        ApricotEatsGorilla("wsdl:#{@action}" => namespaced_options)
      end
      response = @http.request_post(@uri.path, body, headers)
      Savon::Response.new(response)
    end

    # Returns an HTTP connection instance.
    def http
      if @http.nil?
        raise ArgumentError, "Invalid endpoint URI" unless @uri.scheme
        @http = Net::HTTP.new(@uri.host, @uri.port)
        #@http.set_debug_output(STDOUT)
        #@http.read_timeout = 5
      end
      @http
    end

    # Checks if the requestion SOAP action is available.
    # Raises an ArgumentError in case it isn't.
    def validate_action
      unless wsdl.service_methods.include? @action
        raise ArgumentError, "Invalid service method '#{@action}'"
      end
    end

    # Checks if there were any choice elements found in the wsdl and namespaces
    # the corresponding keys from the passed in Hash of options.
    def namespaced_options
      return @options if wsdl.choice_elements.empty?

      options = {}
      @options.each do |key, value|
        key = "wsdl:#{key}" if wsdl.choice_elements.include? key.to_s

        current = options[key]
        case current
        when Array
          options[key] << value
        when nil
          options[key] = value
        else
          options[key] = [current.dup, value]
        end
      end
      options
    end

    # Catches calls to SOAP service methods.
    def method_missing(method, options = {})
      @action = method.to_s
      @options = options
      validate_action
      call_service
    end

  end
end