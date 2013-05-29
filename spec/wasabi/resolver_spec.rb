require 'spec_helper'

describe Wasabi::Resolver do

  subject(:resolver) { Wasabi::Resolver.new(http_test_client) }

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
    fixture = fixture(:authentication)

    xml = resolver.resolve(fixture.path)
    expect(xml).to eq(fixture.read)
  end

  it 'simply returns any raw input' do
    string = '<xml/>'

    xml = resolver.resolve(string)
    expect(xml).to eq(string)
  end

end
