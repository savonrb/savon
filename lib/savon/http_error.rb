# frozen_string_literal: true

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
      String.new("HTTP error (#{@http.code})").tap do |str_error|
        str_error << ": #{@http.body}" unless @http.body.empty?
      end
    end

    def to_hash
      { :code => @http.code, :headers => @http.headers, :body => @http.body }
    end

  end
end
