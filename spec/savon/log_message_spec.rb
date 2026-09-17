# frozen_string_literal: true

require "spec_helper"

RSpec.describe Savon::LogMessage do
  it "returns the message if it's not XML" do
    message = log_message("hello", [:password], :pretty_print).to_s
    expect(message).to eq("hello")
  end

  it "returns the message if it shouldn't be filtered or pretty printed" do
    Nokogiri.expects(:XML).never

    message = log_message("<hello/>", [], false).to_s
    expect(message).to eq("<hello/>")
  end

  it "pretty prints a given message" do
    message = log_message("<envelope><body>hello</body></envelope>", [], :pretty_print).to_s

    expect(message).to include("\n<envelope>")
    expect(message).to include("\n  <body>")
  end

  it "filters tags in a given message without pretty printing" do
    message = log_message("<root><password>secret</password></root>", [:password], false).to_s
    expect(message).to include("<password>***FILTERED***</password>")
    expect(message).not_to include("\n  <password>***FILTERED***</password>") # no pretty printing
  end

  it "filters tags in a given message with pretty printing" do
    message = log_message("<root><password>secret</password></root>", [:password], true).to_s
    expect(message).to include("\n  <password>***FILTERED***</password>")
  end

  it "properly applies Proc filter" do
    filter = proc do |document|
      document.xpath('//password').each do |node|
        node.content = "FILTERED"
      end
    end

    message = log_message("<root><password>secret</password></root>", [filter], false).to_s
    expect(message).to include("<password>FILTERED</password>")
  end

  it "trims a multipart preamble before filtering" do
    multipart = "--MIME_boundary\r\n" \
                "Content-Type: text/xml\r\n" \
                "\r\n" \
                "<root><password>secret</password></root>"

    message = log_message(multipart, [:password], false).to_s
    expect(message).not_to include("--MIME_boundary")
    expect(message).to include("<password>***FILTERED***</password>")
  end

  it "trims a multipart preamble before pretty printing" do
    multipart = "--MIME_boundary\r\n" \
                "Content-Type: text/xml\r\n" \
                "\r\n" \
                "<envelope><body>hello</body></envelope>"

    message = log_message(multipart, [], :pretty_print).to_s
    expect(message).not_to include("--MIME_boundary")
    expect(message).to include("\n<envelope>")
    expect(message).to include("\n  <body>")
  end

  def log_message(*args)
    Savon::LogMessage.new(*args)
  end
end
