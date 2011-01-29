require "savon/soap/xml"
require "savon/soap/part"
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
        @parts = []
        decode_multipart
        raise_errors if Savon.raise_errors?
      end

      attr_accessor :http
      attr_accessor :parts

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

      # Returns the SOAP response header as a Hash.
      def header
        @header_hash ||= basic_hash.find_soap_header
      end

      # Returns the SOAP response body as a Hash.
      def to_hash
        @hash ||= Savon::SOAP::XML.to_hash basic_hash
      end

      # Returns the SOAP response body as an Array.
      def to_array(*path)
        Savon::SOAP::XML.to_array to_hash, *path
      end

      # Returns the complete SOAP response XML without normalization.
      def basic_hash
        @basic_hash ||= Savon::SOAP::XML.parse http.body
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



      # Decoding multipart responses
      #
      # response.to_xml will point to the first part, hopefully the SOAP part of the multipart
      # All attachments are available in the response.parts array. Each is a Part from the mail gem. See the docs there for details but:
      # response.parts[0].body is the contents
      # response.parts[0].headers are the mime headers
      # And you can do nesting:
      # response.parts[0].parts[2].body
      def decode_multipart
        return unless self.http.headers["Content-Type"] =~
            %r|\Amultipart/.*boundary=\"?([^\";,]+)\"?|n
        boundry = "--#{$1}"
        multipart = Savon::SOAP::Part.new(:headers => self.http.headers, :body => http.body)
        multipart.body.split! $1
        @parts = multipart.parts
        http.body = parts.shift.body # I am not supporting the start header. SOAP should be the first part.
      end


    end
  end
end
