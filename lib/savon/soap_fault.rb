# frozen_string_literal: true
module Savon
  class SOAPFault < Error

    def self.present?(http, xml = nil)
      body = xml || http.body
      body = body.encode('UTF-8', 'ISO-8859-1', invalid: :replace, undef: :replace, replace: '') unless body.valid_encoding?
      fault_node  = body.include?("Fault>")
      soap1_fault = body.match(/faultcode\/?\>/) && body.match(/faultstring\/?\>/)
      soap2_fault = body.include?("Code>") && body.include?("Reason>")

      fault_node && (soap1_fault || soap2_fault)
    end

    def initialize(http, nori, xml = nil)
      @xml = xml
      @http = http
      @nori = nori
    end

    attr_reader :http, :nori, :xml

    def to_s
      fault = nori.find(to_hash, 'Fault') || nori.find(to_hash, 'ServiceFault')
      message_by_version(fault)
    end

    def to_hash
      parsed = nori.parse(xml || http.body)
      nori.find(parsed, 'Envelope', 'Body') || {}
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
