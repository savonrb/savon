require "akami"
require "gyoku"
require "uuid"

module Savon
  class Header

    def initialize(globals, locals)
      @gyoku_options  = { :key_converter => globals[:convert_request_keys_to] }

      @wsse_auth      = globals[:wsse_auth]
      @wsse_timestamp = globals[:wsse_timestamp]

      @global_header  = globals[:soap_header]
      @local_header   = locals[:soap_header]

      @globals        = globals
      @locals         = locals

      @header = build
    end

    attr_reader :local_header, :global_header, :gyoku_options,
                :wsse_auth, :wsse_timestamp

    def empty?
      @header.empty?
    end

    def to_s
      @header
    end

    private

    def build
      build_header + build_wsa_header + build_wsse_header
    end

    def build_header
      header =
        if global_header.kind_of?(Hash) && local_header.kind_of?(Hash)
          global_header.merge(local_header)
        elsif local_header
          local_header
        else
          global_header
        end

      convert_to_xml(header)
    end

    def build_wsse_header
      wsse_header = akami
      wsse_header.respond_to?(:to_xml) ? wsse_header.to_xml : ""
    end

    def build_wsa_header
       return '' unless @globals[:use_wsa_headers]
       convert_to_xml({
         'wsa:Action' => @locals[:soap_action],
         'wsa:To' => @globals[:endpoint],
         'wsa:MessageID' => "urn:uuid:#{UUID.new.generate}"
       })
    end

    def convert_to_xml(hash_or_string)
      if hash_or_string.kind_of? Hash
        Gyoku.xml(hash_or_string, gyoku_options)
      else
        hash_or_string.to_s
      end
    end

    def akami
      wsse = Akami.wsse
      wsse.credentials(*wsse_auth) if wsse_auth
      wsse.timestamp = wsse_timestamp if wsse_timestamp
      wsse
    end

  end
end
