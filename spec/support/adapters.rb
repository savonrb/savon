# frozen_string_literal: true

require 'httpi/adapter/httpclient'

# Proxy adapter. Records all requests and passes them to HTTPClient
class AdapterForTest < HTTPI::Adapter::Base
  register :adapter_for_test

  class << self
    attr_reader :requests, :methods

    def reset!
      @requests = []
      @methods = []
    end
  end

  reset!

  def initialize(request)
    self.class.requests << request
    @request = request
    @worker = HTTPI::Adapter::HTTPClient.new(request)
  end

  def client
    @worker.client
  end

  def request(method)
    self.class.methods << method
    @worker.request(method)
  end
end

# Fake adapter with request recording.
# Takes path from url and returns fixture WSDL with that name.
class FakeAdapterForTest < HTTPI::Adapter::Base
  register :fake_adapter_for_test

  class << self
    attr_reader :requests, :methods

    def reset!
      @requests = []
      @methods = []
    end
  end

  reset!

  def initialize(request)
    self.class.requests << request
    @request = request
  end

  attr_reader :client

  def request(method)
    self.class.methods << method
    target = @request.url.path.to_sym
    HTTPI::Response.new(200, {}, Fixture.wsdl(target))
  end
end
