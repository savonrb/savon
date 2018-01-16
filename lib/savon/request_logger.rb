require 'securerandom'
require "savon/log_message"

module Savon
  class RequestLogger

    def initialize(globals)
      @globals = globals
    end

    def log(request, &http_request)
      uuid = SecureRandom.uuid.to_s
      log_request(uuid, request) if log?
      response = http_request.call
      log_response(uuid, response) if log?

      response
    end

    def logger
      @globals[:logger]
    end

    def log?
      @globals[:log]
    end

    private

    def log_request(uuid, request)
      logger.info  { "SOAP Id: #{uuid}, SOAP request: #{request.url}" }
      logger.info  { "SOAP Id: #{uuid}, #{headers_to_log(request.headers)}" }
      logger.debug { "SOAP Id: #{uuid}, #{body_to_log(request.body)}" }
    end

    def log_response(uuid, response)
      logger.info  { "SOAP Id: #{uuid}, SOAP response (status #{response.code})" }
      logger.debug { "SOAP Id: #{uuid}, #{body_to_log(response.body)}" }
    end

    def headers_to_log(headers)
      headers.map { |key, value| "#{key}: #{value}" }.join(", ")
    end

    def body_to_log(body)
      LogMessage.new(body, @globals[:filters], @globals[:pretty_print_xml]).to_s
    end

  end
end
