require "savon/error"

module Savon
  class SOAPFault < Error

    def self.present?(http)
      fault_node  = http.body.include?("Fault>")
      soap1_fault = http.body.include?("faultcode>") && http.body.include?("faultstring>")
      soap2_fault = http.body.include?("Code>") && http.body.include?("Reason>")

      fault_node && (soap1_fault || soap2_fault)
    end

    def initialize(http, nori)
      @http = http
      @nori = nori
    end

    attr_reader :http, :nori

    def to_s
      @message ||= message_by_version to_hash[:fault]
    end

    def to_hash
      @hash ||= nori.parse(@http.body)[:envelope][:body]
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
