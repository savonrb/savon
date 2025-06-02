# frozen_string_literal: true
require "savon/log_message"

module Savon
  class RequestLogger

    def initialize(globals)
      @globals = globals
    end

    def log(request, &http_request)
      log_request(request) if log?
      response = http_request.call
      log_response(response) if log?

      response
    end

    def logger
      @globals[:logger]
    end

    def log?
      @globals[:log]
    end

    def log_headers?
      @globals[:log_headers]
    end
    def log_request(request)
      return unless log?
      logger.info  { "SOAP request: #{request.path}" }
      logger.info  { headers_to_log(request.headers) } if log_headers?
      logger.debug { body_to_log(request.body) }
    end

    def log_response(response)
      return response unless log?
      logger.info  { "SOAP response (status #{response.status})" }
      logger.debug { headers_to_log(response.headers) } if log_headers?
      logger.debug { body_to_log(response.body) }
      response
    end

    private


    def headers_to_log(headers)
      headers.map { |key, value| "#{key}: #{value}" }.join("\n")
    end

    def body_to_log(body)
      LogMessage.new(body, @globals[:filters], @globals[:pretty_print_xml]).to_s.force_encoding(@globals[:encoding])
    end

  end
end
