require "akami"
require "gyoku"

module Savon
  class Header

    def initialize(globals, locals)
      @globals = globals
      @locals = locals
      @wsse = create_wsse
    end

    def empty?
      to_s.empty?
    end

    def to_s
      return @header if @header

      gyoku_options = { :key_converter => @globals[:convert_request_keys_to] }
      @header = (Hash === header ? Gyoku.xml(header, gyoku_options) : header) + wsse_header
    end

    private

    def create_wsse
      wsse = Akami.wsse
      wsse.credentials(*@globals[:wsse_auth]) if @globals.include? :wsse_auth
      wsse.timestamp = @globals[:wsse_timestamp] if @globals.include? :wsse_timestamp
      wsse
    end

    def header
      @header ||= @globals.include?(:soap_header) ? @globals[:soap_header] : {}
    end

    def wsse_header
      @wsse.respond_to?(:to_xml) ? @wsse.to_xml : ""
    end

  end
end
