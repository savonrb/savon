# frozen_string_literal: true

require "savon/options"
require "savon/block_interface"
require "savon/builder"
require "savon/response"
require "savon/http_error"
require "savon/transport/httpi"
require "savon/transport/faraday"
require "mail"

module Savon
  # Represents a single named SOAP operation.
  #
  # Bridges the SOAP layer (envelope building, action headers, multipart) and the
  # transport layer (execution, logging). Knows nothing about transport internals
  # such as proxy, SSL, or auth.
  class Operation

    # SOAP Content-Type values indexed by SOAP version.
    # SOAP 1.1 §6 (HTTP binding), SOAP 1.2 Part 2 §7.1.4 (HTTP media type)
    CONTENT_TYPE = {
      1 => "text/xml;charset=%s",
      2 => "application/soap+xml;charset=%s"
    }.freeze

    # Maps SOAP version to the base MIME type used in multipart requests.
    # RFC 2387 §3.1 (multipart/related Content-Type parameter)
    SOAP_REQUEST_TYPE = {
      1 => "text/xml",
      2 => "application/soap+xml"
    }.freeze

    def self.create(operation_name, wsdl, globals, transport)
      if wsdl.document?
        ensure_name_is_symbol! operation_name
        ensure_exists! operation_name, wsdl
      end

      new(operation_name, wsdl, globals, transport)
    end

    def self.ensure_exists!(operation_name, wsdl)
      unless wsdl.soap_actions.include? operation_name
        raise UnknownOperationError, "Unable to find SOAP operation: #{operation_name.inspect}\n" \
                                     "Operations provided by your service: #{wsdl.soap_actions.inspect}"
      end
    rescue Wasabi::Resolver::HTTPError => e
      raise HTTPError, e.response
    end

    def self.ensure_name_is_symbol!(operation_name)
      unless operation_name.is_a? Symbol
        raise ArgumentError, "Expected the first parameter (the name of the operation to call) to be a symbol\n" \
                             "Actual: #{operation_name.inspect} (#{operation_name.class})"
      end
    end

    def initialize(name, wsdl, globals, transport)
      @name      = name
      @wsdl      = wsdl
      @globals   = globals
      @transport = transport
    end

    def build(locals = {}, &block)
      set_locals(locals, block)
      Builder.new(@name, @wsdl, @globals, @locals)
    end

    # Executes the SOAP operation and returns a Savon::Response.
    #
    # Observer short-circuit: if any registered observer returns a
    # Transport::Response (or legacy HTTPI::Response), the HTTP call
    # is skipped and that response is used directly.
    def call(locals = {}, &block)
      builder  = build(locals, &block)
      response = Savon.notify_observers(@name, builder, @globals, @locals)

      response =
        if response.nil?
          @transport.post(endpoint.to_s, soap_headers(builder), builder.to_s, @locals)
        else
          normalize_observer_response(response)
        end

      create_response(response)
    end

    # Builds and returns the HTTPI::Request that would be sent for this
    # operation, without executing it. Useful for inspection and debugging.
    # Not supported with transport: :faraday.
    def request(locals = {}, &block)
      if @globals[:transport] == :faraday
        raise ArgumentError, "#request returns an HTTPI::Request and is not supported " \
                             "with transport: :faraday. Use client.faraday to configure " \
                             "the connection"
      end

      builder = build(locals, &block)
      @transport.to_httpi_request(endpoint.to_s, soap_headers(builder), builder.to_s, @locals)
    end

    private

    def create_response(response)
      Response.new(response, @globals, @locals)
    end

    def set_locals(locals, block)
      locals = LocalOptions.new(locals)
      BlockInterface.new(locals).evaluate(block) if block

      @locals = locals
    end

    # Assembles the SOAP-level request headers for the given builder.
    #
    # Our responsibility regardless of transport:
    #   * Content-Type (SOAP 1.1 §6 / SOAP 1.2 Part 2 §7.1.4)
    #   * SOAPAction (SOAP 1.1 §6.1.1)
    #   * Multipart Content-Type (RFC 2387), MIME-Version (RFC 2045 §4), Accept-Encoding (RFC 9110 §12.5.3)
    def soap_headers(builder)
      headers = {}

      if builder.multipart
        # RFC 2387 §3 (multipart/related) - SOAP envelope is the root body part
        headers["Content-Type"] = [
          "multipart/related",
          "type=\"#{SOAP_REQUEST_TYPE[@globals[:soap_version]]}\"",
          "start=\"#{builder.multipart[:start]}\"",
          "boundary=\"#{builder.multipart[:multipart_boundary]}\""
        ].join("; ")
        headers["MIME-Version"] = "1.0"
        headers["Accept-Encoding"] = "gzip,deflate"
      else
        headers["Content-Type"] = CONTENT_TYPE[@globals[:soap_version]] % @globals[:encoding]
      end

      action = soap_action
      headers["SOAPAction"] = %("#{action}") if action

      headers
    end

    def soap_action
      # soap_action explicitly set to something falsy
      return if @locals.include?(:soap_action) && !@locals[:soap_action]

      # get the soap_action from local options
      @locals[:soap_action] ||
        # with no local option, but a wsdl, ask it for the soap_action
        @wsdl.document? && @wsdl.soap_action(@name.to_sym) ||
        # if there is no soap_action up to this point, fallback to a simple default
        Gyoku.xml_tag(@name, :key_converter => @globals[:convert_request_keys_to])
    end

    def endpoint
      @globals[:endpoint] || @wsdl.endpoint.tap do |url|
        if @globals[:host]
          host_url = URI.parse(@globals[:host])
          url.host = host_url.host
          url.port = host_url.port
        end
      end
    end

    # Normalizes an observer return value into a Transport::Response.
    #
    # Accepts Transport::Response directly (current contract), wraps
    # HTTPI::Response with a deprecation warning (legacy observer support),
    # and raises on anything else.
    def normalize_observer_response(response)
      return response if response.is_a?(Transport::Response)

      if response.is_a?(HTTPI::Response)
        warn "Observers returning HTTPI::Response is deprecated - return Savon::Transport::Response instead."
        return Transport::Response.from_httpi(response)
      end

      raise Error, "Observers need to return a Savon::Transport::Response " \
                   "to mock the request or nil to execute the request."
    end

  end
end
