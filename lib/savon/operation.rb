# frozen_string_literal: true
require "savon/options"
require "savon/block_interface"
require "savon/request"
require "savon/builder"
require "savon/response"
require "savon/request_logger"
require "savon/http_error"
require "mail"

module Savon
  class Operation

    SOAP_REQUEST_TYPE = {
      1 => "text/xml",
      2 => "application/soap+xml"
    }

    def self.create(operation_name, wsdl, globals)
      if wsdl.document?
        ensure_name_is_symbol! operation_name
        ensure_exists! operation_name, wsdl
      end

      new(operation_name, wsdl, globals)
    end

    def self.ensure_exists!(operation_name, wsdl)
      unless wsdl.soap_actions.include? operation_name
        raise UnknownOperationError, "Unable to find SOAP operation: #{operation_name.inspect}\n" \
                                     "Operations provided by your service: #{wsdl.soap_actions.inspect}"
      end
    rescue Wasabi::Resolver::HTTPError => e
      raise HTTPError.new(e.response)
    end

    def self.ensure_name_is_symbol!(operation_name)
      unless operation_name.kind_of? Symbol
        raise ArgumentError, "Expected the first parameter (the name of the operation to call) to be a symbol\n" \
                             "Actual: #{operation_name.inspect} (#{operation_name.class})"
      end
    end

    def initialize(name, wsdl, globals)
      @name = name
      @wsdl = wsdl
      @globals = globals

      @logger = RequestLogger.new(globals)
    end

    def build(locals = {}, &block)
      set_locals(locals, block)
      Builder.new(@name, @wsdl, @globals, @locals)
    end

    def call(locals = {}, &block)
      builder = build(locals, &block)

      response = Savon.notify_observers(@name, builder, @globals, @locals)
      response ||= call_with_logging build_request(builder)

      raise_expected_httpi_response! unless response.kind_of?(HTTPI::Response)

      create_response(response)
    end

    def request(locals = {}, &block)
      builder = build(locals, &block)
      build_request(builder)
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

    def call_with_logging(request)
      @logger.log(request) { HTTPI.post(request, @globals[:adapter]) }
    end

    def build_request(builder)
      @locals[:soap_action] ||= soap_action
      @globals[:endpoint] ||= endpoint

      request = SOAPRequest.new(@globals).build(
        :soap_action => soap_action,
        :cookies     => @locals[:cookies],
        :headers     => @locals[:headers]
      )

      request.url = endpoint
      request.body = builder.to_s

      if builder.multipart
        request.gzip
        request.headers["Content-Type"] = ["multipart/related",
                                           "type=\"#{SOAP_REQUEST_TYPE[@globals[:soap_version]]}\"",
                                           "start=\"#{builder.multipart[:start]}\"",
                                           "boundary=\"#{builder.multipart[:multipart_boundary]}\""].join("; ")
        request.headers["MIME-Version"] = "1.0"
      end

      request
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

    def raise_expected_httpi_response!
      raise Error, "Observers need to return an HTTPI::Response to mock " \
                   "the request or nil to execute the request."
    end

  end
end
