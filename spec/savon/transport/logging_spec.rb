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
