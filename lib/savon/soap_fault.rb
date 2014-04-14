require "savon"

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
      fault = nori.find(to_hash, 'Fault')
      message_by_version(fault)
    end

    def to_hash
      parsed = nori.parse(@http.body)
      nori.find(parsed, 'Envelope', 'Body')
    end

    private

    def message_by_version(fault)
      if nori.find(fault, 'faultcode')
        code = nori.find(fault, 'faultcode')
        text = nori.find(fault, 'faultstring')

        "(#{code}) #{text}"
      elsif nori.find(fault, 'Code')
        code = nori.find(fault, 'Code', 'Value')
        text = nori.find(fault, 'Reason', 'Text')

        "(#{code}) #{text}"
      end
    end

  end
end
