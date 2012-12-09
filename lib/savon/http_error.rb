require "savon/error"

module Savon
  class HTTPError < Error

    def self.present?(http)
      http.error?
    end

    def initialize(http)
      @http = http
    end

    attr_reader :http

    def to_s
      @message ||= begin
        message = "HTTP error (#{@http.code})"
        message << ": #{@http.body}" unless @http.body.empty?
      end
    end

    def to_hash
      @hash = { :code => @http.code, :headers => @http.headers, :body => @http.body }
    end

  end
end
