require 'httpclient'

class Savon
  class HTTPClient

    def initialize
      @client = ::HTTPClient.new
    end

    attr_reader :client

    def get(url)
      request(:get, url, {}, nil)
    end

    def post(url, headers, body)
      request(:post, url, headers, body)
    end

    private

    def request(method, url, headers, body)
      response = @client.request(method, url, nil, body, headers)
      response.content
    end

  end
end
