require "httpi"
require "savon/soap/response"

module Savon
  module SOAP

    # = Savon::SOAP::Request
    #
    # Executes SOAP requests.
    class Request

      # Content-Types by SOAP version.
      CONTENT_TYPE = { 1 => "text/xml;charset=UTF-8", 2 => "application/soap+xml;charset=UTF-8" }

      # Expects an <tt>HTTPI::Request</tt> and a <tt>Savon::SOAP::XML</tt> object
      # to execute a SOAP request and returns the response.
      def self.execute(config, http, soap)
        new(config, http, soap).response
      end

      # Expects an <tt>HTTPI::Request</tt>, a <tt>Savon::SOAP::XML</tt> object
      # and a <tt>Savon::Config</tt>.
      def initialize(config, http, soap)
        self.config = config
        self.soap = soap
        self.http = configure(http)
      end

      attr_accessor :soap, :http, :config

      # Executes the request and returns the response.
      def response
        @response ||= begin
          response = config.hooks.fire(:soap_request, self) { with_logging { HTTPI.post(http) } }
          SOAP::Response.new(config, response)
        end
      end

      private

      # Configures a given +http+ from the +soap+ object.
      def configure(http)
        http.url = soap.endpoint

        if soap.signature?
          # First generate the document so that Signature can digest sections
          soap.wsse.signature.document = soap.to_xml(true)

          # Then re-generate the document so that Signature can sign the digest
          soap.wsse.signature.document = soap.to_xml(true)

          # The third time we generate the document, we should have a signature
          http.body = soap.to_xml(true)
        else
          http.body = soap.to_xml
        end

        http.headers["Content-Type"] = CONTENT_TYPE[soap.version]
        http.headers["Content-Length"] = soap.to_xml.bytesize.to_s
        http
      end

      # Logs the HTTP request, yields to a given +block+ and returns a <tt>Savon::SOAP::Response</tt>.
      def with_logging
        log_request http.url, http.headers, http.body
        response = yield
        log_response response.code, response.body
        response
      end

      # Logs the SOAP request +url+, +headers+ and +body+.
      def log_request(url, headers, body)
        config.logger.log "SOAP request: #{url}"
        config.logger.log headers.map { |key, value| "#{key}: #{value}" }.join(", ")
        config.logger.log body, :pretty => config.pretty_print_xml, :filter => true
      end

      # Logs the SOAP response +code+ and +body+.
      def log_response(code, body)
        config.logger.log "SOAP response (status #{code}):"
        config.logger.log body, :pretty => config.pretty_print_xml
      end

    end
  end
end
