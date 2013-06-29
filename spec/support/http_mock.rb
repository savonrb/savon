module SpecSupport

  class HTTPMock

    MockError = Class.new(StandardError)

    def initialize
      @fakes = {}
    end

    def client
      :mock_client
    end

    def get(url)
      @fakes[url] or raise_mock_error! :get, url
    end

    def post(url, headers, body)
      @fakes[url] or raise_mock_error! :post, url
    end

    def fake_request(url, fixture = nil)
      @fakes[url] = fixture ? load_fixture(fixture) : ''
    end

    private

    def load_fixture(fixture)
      File.read Fixture.path(fixture)
    end

    def raise_mock_error!(method, url)
      raise MockError, "Unmocked HTTP #{method.to_s.upcase} request to #{url.inspect}"
    end

  end

  def http_mock
    @http_mock ||= HTTPMock.new
  end

end
