require "savon/soap/xml"
require "savon/soap/fault"
require "savon/http/error"

module Savon
  module SOAP

    # = Savon::SOAP::Response
    #
    # Represents the SOAP response and contains the HTTP response.
    class Response

      # Expects an <tt>HTTPI::Response</tt> and handles errors.
      def initialize(response)
        self.http = response
        raise_errors if Savon.raise_errors?
      end

      attr_accessor :http

      # Returns whether the request was successful.
      def success?
        !soap_fault? && !http_error?
      end

      # Returns whether there was a SOAP fault.
      def soap_fault?
        soap_fault.present?
      end

      # Returns the <tt>Savon::SOAP::Fault</tt>.
      def soap_fault
        @soap_fault ||= Fault.new http
      end

      # Returns whether there was an HTTP error.
      def http_error?
        http_error.present?
      end

      # Returns the <tt>Savon::HTTP::Error</tt>.
      def http_error
        @http_error ||= HTTP::Error.new http
      end

      # Returns the SOAP response body as a Hash.
      def original_hash
        @original_hash ||= Savon::SOAP::XML.to_hash to_xml
      end

      # Returns the SOAP response body as a Hash and applies
      # the <tt>Savon.response_pattern</tt> if defined.
      def to_hash
        @hash ||= apply_response_pattern original_hash
      end

      # Returns the SOAP response Hash as an Array.
      def to_array
        @array ||= begin
          array = to_hash.kind_of?(Array) ? to_hash : [to_hash]
          array.compact
        end
      end

      # Returns the SOAP response XML.
      def to_xml
        http.body
      end

    private

      def raise_errors
        raise soap_fault if soap_fault?
        raise http_error if http_error?
      end

      def apply_response_pattern(hash)
        return hash if Savon.response_pattern.blank?
        
        Savon.response_pattern.inject(hash) do |memo, pattern|
          key = case pattern
            when Regexp then memo.keys.find { |key| key.to_s =~ pattern }
            else             memo.keys.find { |key| key.to_s == pattern.to_s }
          end
          
          return hash unless key
          memo[key]
        end
      end

    end
  end
end
