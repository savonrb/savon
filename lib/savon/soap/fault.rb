require "savon/error"
require "savon/soap/xml"

module Savon
  module SOAP

    # = Savon::SOAP::Fault
    #
    # Represents a SOAP fault. Contains the original <tt>HTTPI::Response</tt>.
    class Fault < Error

      # Expects an <tt>HTTPI::Response</tt>.
      def initialize(http)
        self.http = http
      end

      # Accessor for the <tt>HTTPI::Response</tt>.
      attr_accessor :http

      # Returns whether a SOAP fault is present.
      def present?
        @present ||= http.body =~ /<(.+:)?Body>(\s*)<(.+:)?Fault>/
      end

      # Returns the SOAP fault message.
      def to_s
        return "" unless present?
        @message ||= message_by_version to_hash[:fault]
      end

      # Returns the SOAP response body as a Hash.
      def to_hash
        @hash ||= Savon::SOAP::XML.to_hash http.body
      end

    private

      def message_by_version(fault)
        if fault[:faultcode]
          "(#{fault[:faultcode]}) #{fault[:faultstring]}"
        elsif fault[:code]
          "(#{fault[:code][:value]}) #{fault[:reason][:text]}"
        end
      end

    end
  end
end
