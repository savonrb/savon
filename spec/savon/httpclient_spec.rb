require 'spec_helper'

describe Savon::HTTPClient do

  subject(:http) { Savon::HTTPClient.new }

  describe '#client' do
    it 'returns the HTTPClient instance to configure' do
      expect(http.client).to be_an_instance_of(HTTPClient)
    end
  end

  describe '#get' do
    it 'executes an HTTP GET request and returns the raw response' do
      url = 'http://example.com'

      response = mock(content: 'raw get!')
      http.client.expects(:request).with(:get, url, nil, nil, {}).returns(response)

      raw_response = http.get(url)

      expect(raw_response).to eq('raw get!')
    end
  end

  describe '#post' do
    it 'executes an HTTP POST request and returns the raw response' do
      url = 'http://example.com'
      body = 'post request!'
      headers = { 'Content-Length' => 5 }

      response = mock(content: 'raw post!')
      http.client.expects(:request).with(:post, url, nil, body, headers).returns(response)

      raw_response = http.post(url, headers, body)

      expect(raw_response).to eq('raw post!')
    end
  end

end
