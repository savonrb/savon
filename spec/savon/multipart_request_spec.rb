require "spec_helper"

RSpec.describe Savon::Builder do

  let(:globals)     { Savon::GlobalOptions.new({ :endpoint => "http://example.co", :namespace => "http://v1.example.com" }) }
  let(:no_wsdl)     { Wasabi::Document.new }

  it "building multipart request from inline content" do
    locals = {
      attachments: [
        { filename: 'x1.xml', content: '<xml>abc1</xml>'},
        { filename: 'x2.xml', content: '<xml>abc2</xml>'},
      ]
    }
    builder = Savon::Builder.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))
    request_body = builder.to_s

    expect(request_body).to include('Content-Type')
    expect(request_body).to match(/<[a-z]+:operation1>/)

    locals[:attachments].each do |attachment|
      expect(request_body).to match(/^Content-Location: #{attachment[:filename]}\s$/)
      expect(request_body).to include(Base64.encode64(attachment[:content]).strip)
    end

  end

  it "building multipart request from file" do
    locals = {
      attachments: {
        'file.gz' => File.expand_path("../../fixtures/gzip/message.gz", __FILE__)
      }
    }
    builder = Savon::Builder.new(:operation1, no_wsdl, globals, Savon::LocalOptions.new(locals))
    request_body = builder.to_s

    expect(request_body).to include('Content-Type')
    expect(request_body).to match(/<[a-z]+:operation1>/)

    locals[:attachments].each do |id, file|
      expect(request_body).to match(/^Content-Location: #{id}\s$/)
      expect(request_body.gsub("\r", "")).to include(Base64.encode64(File.read(file)).strip)
    end

  end
end