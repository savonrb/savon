# frozen_string_literal: true
require "savon/options"
require "savon/block_interface"
require "savon/request"
require "savon/builder"
require "savon/response"
require "savon/request_logger"
require "savon/http_error"
require "mail"
require 'faraday/gzip'


module Savon
  class Operation

    SOAP_REQUEST_TYPE = {
      1 => "text/xml",
      2 => "application/soap+xml"
    }
    SOAP_REQUEST_TYPE_MTOM = "application/xop+xml"

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
      response ||= call_with_logging build_connection(builder)

      raise_expected_faraday_response! unless response.kind_of?(Faraday::Response)

      create_response(response)
    end

    def request(locals = {}, &block)
      builder = build(locals, &block)
      connection = build_connection(builder)
      connection.build_request(:post) do |req|
        req.url(@globals[:endpoint])
        req.body = @locals[:body]
      end
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

    def call_with_logging(connection)
      ntlm_auth = handle_ntlm(connection) if @globals.include?(:ntlm)
      @logger.log_response(connection.post(@globals[:endpoint]) { |request|
        request.body = @locals[:body]
        request.headers['Authorization'] = "NTLM #{auth.encode64}" if ntlm_auth
        @logger.log_request(request)
      })
    end

    def handle_ntlm(connection)
      ntlm_message = Net::NTLM::Message
      response = connection.get(@globals[:endpoint]) do |request|
        request.headers['Authorization'] = 'NTLM ' + ntlm_message::Type1.new.encode64
      end
      challenge = response.headers['www-authenticate'][/(?:NTLM|Negotiate) (.*)$/, 1]
      message = ntlm_message::Type2.decode64(challenge)
      message.response([:user, :password, :domain].zip(@globals[:ntlm]).to_h)
    end

    def build_connection(builder)
      @globals[:endpoint] ||= endpoint
      @locals[:soap_action] ||= soap_action
      @locals[:body] = builder.to_s
      @connection = SOAPRequest.new(@globals).build(
        :soap_action => soap_action,
        :cookies     => @locals[:cookies],
        :headers     => @locals[:headers]
      ) do |connection|
        if builder.multipart
          ctype_headers = ["multipart/related"]
          if @locals[:mtom]
            ctype_headers << "type=\"#{SOAP_REQUEST_TYPE_MTOM}\""
            ctype_headers << "start-info=\"text/xml\""
          else
            ctype_headers << "type=\"#{SOAP_REQUEST_TYPE[@globals[:soap_version]]}\""
            connection.request :gzip
          end
          connection.headers["Content-Type"] = (ctype_headers + ["start=\"#{builder.multipart[:start]}\"",
                                                  "boundary=\"#{builder.multipart[:multipart_boundary]}\""]).join("; ")
          connection.headers["MIME-Version"] = "1.0"
        end

        connection.headers["Content-Length"] = @locals[:body].bytesize.to_s
      end
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

    def raise_expected_faraday_response!
      raise Error, "Observers need to return a Faraday::Response to mock " \
                   "the request or nil to execute the request."
    end

  end
end
