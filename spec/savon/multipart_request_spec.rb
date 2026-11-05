# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::Builder do
  let(:globals)     { Savon::GlobalOptions.new({ endpoint: "http://example.co", namespace: "http://v1.example.com" }) }
  let(:no_wsdl)     { Wasabi::Document.new }

  it "building multipart request from inline content" do
    locals = {
      attachments: [
        { filename: 'x1.xml', content: '<xml>abc1</xml>' },
        { filename: 'x2.xml', content: '<xml>abc2</xml>' }
      ]
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))
    request_body = builder.to_s

    expect(request_body).to include('Content-Type')
    expect(request_body).to match(/<[a-z]+:operation1>/)
    expect(request_body).to include("Content-Type: text/xml")
    root_part_index = request_body.index("Content-Type: text/xml")
    attachment_index = request_body.index("Content-Location: x1.xml")
    expect(root_part_index).to be < attachment_index

    locals[:attachments].each do |attachment|
      expect(request_body).to match(/^Content-Location: #{attachment[:filename]}\s$/)
      expect(request_body).to include(Base64.encode64(attachment[:content]).strip)
    end
  end

  it "building multipart request from a pre-built :xml envelope" do
    envelope = '<soap:Envelope><soap:Body><tns:operation1/></soap:Body></soap:Envelope>'
    locals = {
      xml: envelope,
      attachments: [
        { filename: 'x1.xml', content: '<xml>abc1</xml>' },
        { filename: 'x2.xml', content: '<xml>abc2</xml>' }
      ]
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))
    request_body = builder.to_s

    expect(request_body).to include('Content-Type')
    expect(request_body).to include(envelope)

    locals[:attachments].each do |attachment|
      expect(request_body).to match(/^Content-Location: #{attachment[:filename]}\s$/)
      expect(request_body).to include(Base64.encode64(attachment[:content]).strip)
    end
  end

  [
    {
      label: "SOAP 1.1",
      soap_version: 1,
      soap_namespace: "http://schemas.xmlsoap.org/soap/envelope/",
      root_part_type: "text/xml"
    },
    {
      label: "SOAP 1.2",
      soap_version: 2,
      soap_namespace: "http://www.w3.org/2003/05/soap-envelope",
      root_part_type: "application/soap+xml"
    }
  ].each do |mtom_case|
    it "building an MTOM #{mtom_case[:label]} request from a pre-built :xml envelope" do
      request_body = mtom_request_body(
        soap_namespace: mtom_case[:soap_namespace],
        globals: globals_for_soap_version(mtom_case[:soap_version])
      )

      expect(unfold_mime_headers(request_body)).to include(
        %(Content-Type: application/xop+xml; charset=UTF-8; type="#{mtom_case[:root_part_type]}")
      )
      expect(request_body).to include('<xop:Include href="cid:doc1@example"/>')
      expect(request_body).to include('Content-ID: <doc1@example>')
      expect(request_body).to include('Content-Transfer-Encoding: binary')
    end
  end

  it "uses content_id: for the Content-ID instead of the filename" do
    locals = {
      attachments: [
        { filename: 'my report (1).pdf', content_id: 'report-1@example', content: '<xml>abc1</xml>' },
        { filename: 'my report (1).pdf', content_id: 'report-2@example', content: '<xml>abc2</xml>' }
      ]
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))
    request_body = builder.to_s

    expect(request_body).to include('Content-ID: <report-1@example>')
    expect(request_body).to include('Content-ID: <report-2@example>')
    expect(request_body).not_to include('Content-ID: <my report (1).pdf>')
    # Content-Location follows the Content-ID, not the filename.
    expect(request_body).to match(/^Content-Location: report-1@example\s$/)
    expect(request_body).to match(/^Content-Location: report-2@example\s$/)
    expect(request_body).to include(Base64.encode64('<xml>abc1</xml>').strip)
    expect(request_body).to include(Base64.encode64('<xml>abc2</xml>').strip)
  end

  it "raises for an explicit content_id: that is not a valid Content-ID" do
    locals = {
      attachments: [
        { filename: 'a.pdf', content_id: 'has space@y', content: '<xml>abc1</xml>' }
      ]
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))

    expect { builder.to_s }.to raise_error(ArgumentError, /Invalid Content-ID "has space@y"/)
  end

  it "raises for an MTOM attachment whose filename is not a valid Content-ID" do
    locals = {
      mtom: true,
      xml: '<soap:Envelope><soap:Body><tns:operation1/></soap:Body></soap:Envelope>',
      attachments: [
        { filename: 'my report (1).pdf', content: '<xml>abc1</xml>' }
      ]
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))

    expect { builder.to_s }.to raise_error(ArgumentError, /Invalid Content-ID "my report \(1\).pdf"/)
  end

  it "warns instead of raising for a plain attachment whose filename is not a valid Content-ID" do
    locals = {
      attachments: [
        { filename: 'my report (1).pdf', content: '<xml>abc1</xml>' }
      ]
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))

    expect { builder.to_s }.to output(/Invalid Content-ID "my report \(1\).pdf"/).to_stderr
  end

  it "uses content_id: for the Content-ID of a hash attachment" do
    locals = {
      attachments: {
        'doc1@example' => { filename: 'doc1.xml', content_id: 'other@example', content: '<xml>abc1</xml>' }
      }
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))
    request_body = builder.to_s

    expect(request_body).to include('Content-ID: <other@example>')
    expect(request_body).not_to include('Content-ID: <doc1@example>')
    # Content-Location follows the Content-ID, not the filename.
    expect(request_body).to match(/^Content-Location: other@example\s$/)
  end

  it "does not mutate caller-provided XML encoding for MTOM requests" do
    envelope = '<soap:Envelope><soap:Body><tns:operation1/></soap:Body></soap:Envelope>'.encode(Encoding::UTF_8).freeze
    locals = {
      xml: envelope,
      mtom: true,
      attachments: [
        { filename: 'x1.xml', content: '<xml>abc1</xml>' }
      ]
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))

    expect { builder.to_s }.not_to raise_error
    expect(envelope.encoding).to eq(Encoding::UTF_8)
  end

  it "building multipart request from file" do
    locals = {
      attachments: {
        'file.gz' => File.expand_path('../fixtures/gzip/message.gz', __dir__)
      }
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))
    request_body = builder.to_s

    expect(request_body).to include('Content-Type')
    expect(request_body).to match(/<[a-z]+:operation1>/)

    locals[:attachments].each do |id, file|
      expect(request_body).to match(/^Content-Location: #{id}\s$/)
      expect(request_body.gsub("\r", "")).to include(Base64.encode64(File.read(file)).strip)
    end
  end

  it "applies log filters to the XML part of a built multipart request" do
    locals = {
      xml: %(<?xml version="1.0" encoding="UTF-8"?><Envelope><password>secret</password></Envelope>),
      mtom: true,
      attachments: [{ filename: "a.txt", content: "plain" }]
    }
    body = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals)).to_s

    logged = Savon::LogMessage.new(body, [:password], false).to_s

    expect(logged).to include("<password>***FILTERED***</password>")
    expect(logged).not_to include("secret")
  end

  def mtom_request_body(soap_namespace:, globals:)
    envelope = <<~XML
      <soap:Envelope xmlns:soap="#{soap_namespace}"
                     xmlns:xop="http://www.w3.org/2004/08/xop/include">
        <soap:Body><tns:upload><xop:Include href="cid:doc1@example"/></tns:upload></soap:Body>
      </soap:Envelope>
    XML
    locals = {
      xml: envelope,
      mtom: true,
      attachments: {
        'doc1@example' => { filename: 'doc1.xml', content: '<xml>abc1</xml>' }
      }
    }
    builder = described_class.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))
    builder.to_s
  end

  def globals_for_soap_version(soap_version)
    return globals if soap_version == 1

    Savon::GlobalOptions.new(
      endpoint: "http://example.co",
      namespace: "http://v1.example.com",
      soap_version: soap_version
    )
  end

  # Mail folds long MIME headers onto whitespace-prefixed continuation lines.
  def unfold_mime_headers(message)
    message.gsub(/\r?\n[ \t]+/, " ")
  end
end
