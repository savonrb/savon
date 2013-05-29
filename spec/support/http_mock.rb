module SpecSupport

  class HTTPMock

    MockError = Class.new(StandardError)

    def initialize
      @fakes = {}
    end

    def get(url)
      @fakes[url] or raise_mock_error! url
    end

    def fake_request(url, fixture)
      @fakes[url] = load_fixture(fixture)
    end

    private

    def load_fixture(fixture)
      Fixture.new(fixture).read
    end

    def raise_mock_error!(url)
      raise MockError, "Unmocked HTTP request to #{url.inspect}"
    end

  end

  def http_mock
    @http_mock ||= HTTPMock.new
  end

end
