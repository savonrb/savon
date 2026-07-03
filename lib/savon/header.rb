# frozen_string_literal: true

require "akami"
require "gyoku"
require "securerandom"

module Savon
  # Assembles the SOAP +Header+ element of a request envelope and renders it to
  # XML.
  #
  # A SOAP Header carries a request's out-of-band metadata. This object is
  # responsible for every header block Savon can emit, concatenated in this
  # order:
  #
  # 1. application headers supplied by the caller (the +soap_header+ option),
  # 2. the WS-Addressing headers +wsa:Action+, +wsa:To+ and +wsa:MessageID+
  #    (WS-Addressing 1.0 - Core §3),
  # 3. the WS-Security header with UsernameToken credentials, a +wsu:Timestamp+
  #    and an XML Signature (OASIS WSS SOAP Message Security 1.1).
  #
  # WS-Security markup is delegated to Akami and Hash-to-XML conversion to Gyoku.
  class Header
    # @param globals [Savon::GlobalOptions] client-level options, read for the
    #   Gyoku key converter (+:convert_request_keys_to+) and the WS-Addressing
    #   toggle (+:use_wsa_headers+)
    # @param effective [Savon::EffectiveOptions] resolves the WSSE, soap_header,
    #   soap_action and endpoint values for the request
    def initialize(globals, effective)
      @gyoku_options  = { key_converter: globals[:convert_request_keys_to] }

      @wsse_auth      = effective.wsse_auth
      @wsse_timestamp = effective.wsse_timestamp
      @wsse_signature = effective.wsse_signature
      @soap_header    = effective.soap_header

      @globals        = globals
      @effective      = effective
      @header         = build
    end

    attr_reader :gyoku_options, :wsse_auth, :wsse_timestamp, :wsse_signature

    # @return [Boolean] whether the rendered header is empty, i.e. there is no
    #   header content to include in the envelope
    def empty?
      @header.empty?
    end

    # Returns the rendered SOAP header XML. The header is built once during
    # construction and cached, so this is a cheap, repeatable read.
    #
    # @return [String] the header XML (may be empty)
    def to_s
      @header
    end

    private

    # Concatenates the three header sections in document order: caller content,
    # WS-Addressing, then WSSE security.
    #
    # @return [String]
    def build
      build_header + build_wsa_header + build_wsse_header
    end

    # Renders the resolved soap_header. {Savon::EffectiveOptions#soap_header}
    # merges the global and local values, so there is nothing to combine here.
    # Hash-to-XML conversion only. Strings pass through.
    #
    # @return [String]
    def build_header
      convert_to_xml(@soap_header)
    end

    # Builds the WS-Security header via Akami, or an empty string when no WSSE
    # content (credentials, timestamp or signature) applies.
    #
    # @return [String]
    def build_wsse_header
      wsse_header = akami
      wsse_header.respond_to?(:to_xml) ? wsse_header.to_xml : ""
    end

    # Builds the WS-Addressing header, that's +wsa:Action+, +wsa:To+ and a freshly
    # generated +wsa:MessageID+ (WS-Addressing 1.0 - Core §3). +wsa:Action+ carries
    # the resolved SOAPAction and +wsa:To+ the resolved endpoint. Emitted only when
    # the +:use_wsa_headers+ global is set. Otherwise returns an empty string.
    #
    # @return [String]
    def build_wsa_header
      return '' unless @globals[:use_wsa_headers]

      convert_to_xml({
        'wsa:Action'    => @effective.soap_action,
        'wsa:To'        => @effective.endpoint,
        'wsa:MessageID' => "urn:uuid:#{SecureRandom.uuid}"
      })
    end

    # Renders a header value to XML. A Hash goes through Gyoku (honouring the
    # configured key converter), anything else is coerced with +#to_s+.
    #
    # @param hash_or_string [Hash, #to_s] the header content
    # @return [String]
    def convert_to_xml(hash_or_string)
      if hash_or_string.is_a? Hash
        Gyoku.xml(hash_or_string, gyoku_options)
      else
        hash_or_string.to_s
      end
    end

    # Configures an Akami WSSE object from the resolved WSSE options. Sets the
    # UsernameToken credentials, enables the wsu:Timestamp, and attaches the XML
    # Signature when a document has been assigned to it.
    #
    # @return [Akami::WSSE] configured, not yet serialized
    def akami
      wsse = Akami.wsse
      wsse.credentials(*wsse_auth) if wsse_auth
      wsse.timestamp = wsse_timestamp if wsse_timestamp
      if wsse_signature&.have_document?
        wsse.signature = wsse_signature
      end

      wsse
    end
  end
end
