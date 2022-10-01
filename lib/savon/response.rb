# frozen_string_literal: true
require "nori"
require "savon/soap_fault"
require "savon/http_error"

module Savon
  class Response
    CRLF = /\r\n/
    WSP  = /[#{%Q|\x9\x20|}]/

    def initialize(http, globals, locals)
      @http    = http
      @globals = globals
      @locals  = locals
      @attachments = []
      @xml     = ''
      @has_parsed_body = false

      build_soap_and_http_errors!
      raise_soap_and_http_errors! if @globals[:raise_errors]
    end

    attr_reader :http, :globals, :locals, :soap_fault, :http_error

    def success?
      !soap_fault? && !http_error?
    end
    alias_method :successful?, :success?

    def soap_fault?
      SOAPFault.present?(@http, xml)
    end

    def http_error?
      HTTPError.present? @http
    end

    def header
      find('Header')
    end

    def body
      find('Body')
    end

    alias_method :to_hash, :body

    def to_array(*path)
      result = path.inject body do |memo, key|
        return [] if memo[key].nil?
        memo[key]
      end

      result.kind_of?(Array) ? result.compact : [result].compact
    end

    def response_hash
      @hash ||= nori.parse(xml)
    end

    def xml
      if multipart?
        parse_body unless @has_parsed_body
        @xml
      else
        @http.body
      end
    end

    alias_method :to_xml, :xml
    alias_method :to_s,   :xml

    def doc
      @doc ||= Nokogiri.XML(xml)
    end

    def xpath(path, namespaces = nil)
      doc.xpath(path, namespaces || xml_namespaces)
    end

    def find(*path)
      envelope = nori.find(response_hash, 'Envelope')
      raise_invalid_response_error! unless envelope.is_a?(Hash)

      nori.find(envelope, *path)
    end

    def attachments
      if multipart?
        parse_body unless @has_parsed_body
        @attachments
      else
        []
      end
    end

    def multipart?
      !(http.headers['content-type'] =~ /^multipart/im).nil?
    end

    private

    def boundary
      return unless multipart?
      Mail::Field.new('content-type', http.headers['content-type']).parameters['boundary']
    end

    def parse_body
      http.body.force_encoding Encoding::ASCII_8BIT
      parts = http.body.split(/(?:\A|\r\n)--#{Regexp.escape(boundary)}(?=(?:--)?\s*$)/)
      parts[1..-1].to_a.each_with_index do |part, index|
        header_part, body_part = part.lstrip.split(/#{CRLF}#{CRLF}|#{CRLF}#{WSP}*#{CRLF}(?!#{WSP})/m, 2)
        section = Mail::Part.new(
          body: body_part
        )
        section.header = header_part
        if index == 0
          @xml = section.body.to_s
        else
          @attachments << section
        end
      end
      @has_parsed_body = true
    end

    def build_soap_and_http_errors!
      @soap_fault = SOAPFault.new(@http, nori, xml) if soap_fault?
      @http_error = HTTPError.new(@http) if http_error?
    end

    def raise_soap_and_http_errors!
      raise soap_fault if soap_fault?
      raise http_error if http_error?
    end

    def raise_invalid_response_error!
      raise InvalidResponseError, "Unable to parse response body:\n" + xml.inspect
    end

    def xml_namespaces
      @xml_namespaces ||= doc.collect_namespaces
    end

    def nori
      return @nori if @nori

      nori_options = {
        :delete_namespace_attributes => @globals[:delete_namespace_attributes],
        :strip_namespaces            => @globals[:strip_namespaces],
        :convert_tags_to             => @globals[:convert_response_tags_to],
        :convert_attributes_to       => @globals[:convert_attributes_to],
        :advanced_typecasting        => @locals[:advanced_typecasting],
        :parser                      => @locals[:response_parser]
      }

      non_nil_nori_options = nori_options.reject { |_, value| value.nil? }
      @nori = Nori.new(non_nil_nori_options)
    end

  end
end
