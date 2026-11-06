# frozen_string_literal: true

module Savon
  module Transport
    # Validates outbound HTTP header values before a transport sends them.
    #
    # A value that carries control characters cannot be sent safely.
    # A carriage return or line feed splits the header on the wire,
    # which lets an attacker inject further request headers.
    # A header value can be assembled from input the caller does not fully control,
    # so it is checked here rather than trusted where it is built.
    #
    # The check runs at the transport layer on the fully merged header set,
    # so it covers every source of a value alike. It is the policing half of
    # a deliberate split: the request headers are built elsewhere, this module
    # decides whether they may be sent.
    #
    # RFC 9110 §5.5 (field values)
    module HeaderValidation
      # Control characters that must never appear in an HTTP header value.
      # A carriage return or line feed splits the header, a NUL truncates it.
      ILLEGAL_HEADER_CHARACTERS = /[\r\n\0]/
      private_constant :ILLEGAL_HEADER_CHARACTERS

      private

      # Validates every SOAPAction header and raises if one is unsafe.
      #
      # The SOAPAction value can come from untrusted WSDL input, which may encode
      # a carriage return or line feed as the character references +&#13;+ and +&#10;+.
      # These survive XML attribute-value normalization and reach the header as real
      # control characters.
      #
      # The merged headers are a plain Hash, so a caller can add a SOAPAction under
      # a Symbol or a differently cased key next to the default String key.
      # Some adapters send both, so every key that names SOAPAction is checked,
      # matched case-insensitively.
      #
      # Pure validation. The value is never trimmed, stripped, or encoded.
      # A header that cannot be sent safely is rejected, not repaired.
      # Leading, interior, and trailing control characters all fail.
      # The value is checked as raw bytes, so a non-String value or a string
      # with an invalid encoding never raises here.
      # The offending value is included in the message because it's not a secret.
      #
      # SOAP 1.1 §6.1.1 (SOAPAction HTTP header)
      #
      # @param headers [Hash{String, Symbol => Object}] the merged outbound HTTP headers
      # @return [void]
      # @raise [Savon::InvalidHeaderError] when a SOAPAction contains CR, LF, or NUL
      def validate_soap_action_header!(headers)
        headers.each do |key, value|
          next unless value && key.to_s.casecmp?("SOAPAction")
          next unless ILLEGAL_HEADER_CHARACTERS.match?(value.to_s.b)

          raise InvalidHeaderError, "The SOAPAction header contains illegal control " \
                                    "characters (CR, LF, or NUL): #{value.inspect}"
        end
      end
    end
  end
end
