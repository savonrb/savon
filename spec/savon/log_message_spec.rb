require "spec_helper"

describe Savon::LogMessage do

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
    expect(message).to_not include("\n  <password>***FILTERED***</password>") # no pretty printing
  end

  it "filters tags in a given message with pretty printing" do
    message = log_message("<root><password>secret</password></root>", [:password], true).to_s
    expect(message).to include("\n  <password>***FILTERED***</password>")
  end

  it "properly applies Proc filter" do
    filter = Proc.new do |document|
      document.xpath('//password').each do |node|
        node.content = "FILTERED"
      end
    end

    message = log_message("<root><password>secret</password></root>", [filter], false).to_s
    expect(message).to include("<password>FILTERED</password>")
  end

  def log_message(*args)
    Savon::LogMessage.new(*args)
  end

end
