# frozen_string_literal: true

require "savon/log_message"

module Savon
  module Transport
    # Shared logging behaviour for HTTP transports.
    #
    # Expects the including class to expose @globals (Savon::GlobalOptions)
    # so that log level, filters, and pretty-print settings can be accessed.
    #
    # log_request and log_response are intentionally private so that each
    # transport drives them from its own post method.
    module Logging
      private

      def log?
        @globals[:log]
      end

      def log_headers?
        @globals[:log_headers]
      end

      def logger
        @globals[:logger]
      end

      # Logs the outbound request at INFO (URL and optional headers)
      # and DEBUG (filtered/pretty-printed body).
      #
      # @param url     [String] the SOAP endpoint URL
      # @param headers [Hash]   request headers
      # @param body    [String] the serialized SOAP envelope
      def log_request(url, headers, body)
        logger.info  do "SOAP request: #{url}" end
        logger.info  { headers_to_log(headers) } if log_headers?
        logger.debug { body_to_log(body) }
      end

      # Logs the inbound response at INFO (status line)
      # and DEBUG (headers and filtered/pretty-printed body).
      #
      # @param response [Transport::Response]
      def log_response(response)
        logger.info  do "SOAP response (status #{response.code})" end
        logger.debug { headers_to_log(response.headers) } if log_headers?
        logger.debug { body_to_log(response.body) }
      end

      def headers_to_log(headers)
        headers.map { |key, value| "#{key}: #{value}" }.join("\n")
      end

      def body_to_log(body)
        message = LogMessage.new(body, @globals[:filters], @globals[:pretty_print_xml]).to_s

        # A multipart body is tagged binary only so its parts can be concatenated: the text parts are already in the
        # log encoding. Transcoding from ASCII-8BIT would replace every non-ASCII byte, the text included, so relabel
        # the bytes and replace only those that are invalid in the log encoding (the binary attachments).
        return message.dup.force_encoding(@globals[:encoding]).scrub if message.encoding == Encoding::BINARY

        message.encode(@globals[:encoding], invalid: :replace, undef: :replace)
      end
    end
  end
end
