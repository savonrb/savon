require "httpi"
require "savon/soap/response"

module Savon
  module SOAP

    # = Savon::SOAP::Request
    #
    # Executes SOAP requests.
    class Request

      # Content-Types by SOAP version.
      ContentType = { 1 => "text/xml;charset=UTF-8", 2 => "application/soap+xml;charset=UTF-8" }

      # Expects an <tt>HTTPI::Request</tt> and a <tt>Savon::SOAP::XML</tt> object.
      def initialize(request, soap)
        self.request = setup(request, soap)
      end

      # Accessor for the <tt>HTTPI::Request</tt>.
      attr_accessor :request

      # Executes the request and returns the response.
      def response
        @response ||= with_logging { HTTPI.post request }
      end

    private

      # Sets up the +request+ using a given +soap+ object.
      def setup(request, soap)
        request.url = soap.endpoint
        if soap.has_parts? # do multipart stuff if soap has parts
          request_message = soap.request_message
          # takes relevant http headers from the "Mail" message and makes them Net::HTTP compatible
          request.headers["Content-Type"] ||= ContentType[soap.version]
          request_message.header.fields.each do |field|
            request.headers[field.name] = field.to_s
          end
          #request.headers["Content-Type"] << %|; start="<savon_soap_xml_part>"|
          request_message.body.set_sort_order soap.parts_sort_order if soap.parts_sort_order && soap.parts_sort_order.any?
          request.body = request_message.body.encoded
        else
          request.headers["Content-Type"] ||= ContentType[soap.version]
          request.body = soap.to_xml
        end
        request
      end

      # Logs the HTTP request, yields to a given +block+ and returns a <tt>Savon::SOAP::Response</tt>.
      def with_logging
        log_request request.url, request.headers, request.body
        response = yield
        log_response response.code, response.body
        SOAP::Response.new response
      end

      # Logs the SOAP request +url+, +headers+ and +body+.
      def log_request(url, headers, body)
        Savon.log "SOAP request: #{url}"
        Savon.log headers.map { |key, value| "#{key}: #{value}" }.join(", ")
        Savon.log body
      end

      # Logs the SOAP response +code+ and +body+.
      def log_response(code, body)
        Savon.log "SOAP response (status #{code}):"
        Savon.log body
      end

    end
  end
end
