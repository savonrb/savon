# frozen_string_literal: true
require "savon"

module Savon
  class InvalidResponseError < Error
    attr_reader :http, :xml

    def initialize(http, xml)
      @http, @xml = http, xml
    end

    def to_s
      "Unable to parse response body:\n" + xml.inspect
    end
  end
end
