module SpecSupport

  def mock_request(url, fixture_name)
    response = HTTPI::Response.new 200, {}, fixture(fixture_name).read
    HTTPI.expects(:get).with { |r| r.url == URI(url) }.returns(response)
  end

end
