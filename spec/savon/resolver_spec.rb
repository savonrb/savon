require 'spec_helper'

describe Savon::Resolver do

  subject(:resolver) { Savon::Resolver.new(http_test_client) }

  let(:http_test_client) {
    Class.new {

      def get(url)
        "raw_response for #{url}"
      end

    }.new
  }

  it 'resolves remote files using a simple HTTP client interface' do
    url = 'http://example.com?wsdl'

    xml = resolver.resolve(url)
    expect(xml).to eq("raw_response for #{url}")
  end

  it 'resolves local files' do
    fixture = fixture('wsdl/authentication')

    xml = resolver.resolve(fixture)
    expect(xml).to eq(File.read(fixture))
  end

  it 'simply returns any raw input' do
    string = '<xml/>'

    xml = resolver.resolve(string)
    expect(xml).to eq(string)
  end

end
