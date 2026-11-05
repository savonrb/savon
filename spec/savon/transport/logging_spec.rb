# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::Transport::Logging do
  subject(:transport) { transport_class.new(globals) }

  let(:globals) { Savon::GlobalOptions.new }
  let(:transport_class) do
    Class.new do
      include Savon::Transport::Logging

      def initialize(globals)
        @globals = globals
      end

      def logged_body(body)
        body_to_log(body)
      end
    end
  end

  it "keeps XML body logging filterable and readable" do
    globals.filters(:password)
    globals.pretty_print_xml(true)

    message = transport.logged_body("<root><password>secret</password></root>")

    expect(message).to include("\n  <password>***FILTERED***</password>")
    expect(message.encoding).to eq(Encoding::UTF_8)
  end

  it "keeps non-latin text in binary-tagged multipart bodies" do
    body = +"--boundary\r\nContent-Type: application/xop+xml\r\n\r\n<root>\u043F\u0440\u0438\u0432\u0435\u0442</root>"
    body.force_encoding("BINARY")

    message = transport.logged_body(body)

    expect(message).to include("<root>\u043F\u0440\u0438\u0432\u0435\u0442</root>")
    expect(message).to be_valid_encoding
    expect(message.encoding).to eq(Encoding::UTF_8)
  end

  it "keeps the text of a multipart body that carries a binary attachment" do
    body = "--b\r\nContent-Type: application/xop+xml\r\n\r\n<a>\u0412\u044B\u043F\u0438\u0441\u043A\u0430</a>\r\n--b\r\n\r\n".b +
           "%PDF-\xFF\xFE\x80".b + "\r\n--b--".b

    message = transport.logged_body(body)

    expect(message).to be_valid_encoding
    expect(message.encoding).to eq(Encoding::UTF_8)
    expect(message).to include("<a>\u0412\u044B\u043F\u0438\u0441\u043A\u0430</a>")
  end

  it "replaces invalid bytes in binary multipart bodies" do
    body = +"--boundary\r\nContent-Type: application/octet-stream\r\n\r\n"
    body << "\xFF".b
    body.force_encoding("UTF-8")

    message = transport.logged_body(body)

    expect(message).to be_valid_encoding
    expect(message).to include("--boundary")
    expect(message).to include("\uFFFD")
  end
end
