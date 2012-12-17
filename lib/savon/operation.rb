require "savon/options"
require "savon/block_interface"
require "savon/request"
require "savon/builder"

module Savon
  class Operation

    def self.create(operation_name, wsdl, globals)
      if wsdl.document?
        ensure_name_is_symbol! operation_name
        ensure_exists! operation_name, wsdl
      end

      new(operation_name, wsdl, globals)
    end

    def self.ensure_exists!(operation_name, wsdl)
      unless wsdl.soap_actions.include? operation_name
        raise ArgumentError, "Unable to find SOAP operation: #{operation_name.inspect}\n" \
                             "Operations provided by your service: #{wsdl.soap_actions.inspect}"
      end
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
    end

    def call(locals = {}, &block)
      @locals = LocalOptions.new(locals)

      BlockInterface.new(@locals).evaluate(block) if block

      builder = Builder.new(@name, @wsdl, @globals, @locals)
      request = Request.new(@name, @wsdl, @globals, @locals)

      response = Savon.notify_observers(@name, builder, @globals, @locals)
      response ||= request.call(builder.to_s)

      raise_expected_httpi_response! unless response.kind_of?(HTTPI::Response)

      Response.new(response, @globals, @locals)
    end

    private

    def raise_expected_httpi_response!
      raise Error, "Observers need to return an HTTPI::Response to mock " \
                   "the request or nil to execute the request."
    end

    def log(message)
      @globals[:logger].log(message)
    end

  end
end
