require "wasabi"
require "httpi/request"

module Savon
  module Wasabi

    # = Savon::Wasabi::Document
    #
    # Extends the document handling of the <tt>Wasabi::Document</tt> by
    # adding support for remote and local WSDL documents.
    class Document < ::Wasabi::Document

      # Hooks into Wasabi and extends its document handling.
      def xml
        @xml ||= document.kind_of?(String) ? resolve_document : document
      end

      # Sets the <tt>HTTPI::Request</tt> for remote WSDL documents.
      attr_writer :request

      private

      # Sets up and returns the <tt>HTTPI::Request</tt>.
      def request
        @request ||= HTTPI::Request.new
        @request.url = document
        @request
      end

      # Resolves and returns the raw WSDL document.
      def resolve_document
        case document
          when /^http[s]?:/ then
            response = HTTPI.get(request)
            if response.error?
              raise Savon::HTTP::Error.new(response)
            else
              response.body
            end
          when /^</         then document
          else                   File.read(document)
        end
      end

    end
  end
end
