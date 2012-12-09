require "gyoku"

module Savon
  class Header

    def initialize(globals, locals)
      @wsse = :replace_me_with_something_real
      @globals = globals
      @locals = locals
    end

    def empty?
      to_s.empty?
    end

    def to_s
      @string ||= (Hash === header ? Gyoku.xml(header) : header) + wsse_header
    end

    private

    def header
      @header ||= @globals.soap_header? ? @globals[:soap_header] : {}
    end

    def wsse_header
      @wsse.respond_to?(:to_xml) ? @wsse.to_xml : ""
    end
  end
end
