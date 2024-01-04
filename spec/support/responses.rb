class Responses
  class << self
    def mock_faraday(code, headers, body)
      env = Faraday::Env.new(status: code, response_headers: headers, response_body: body)
      Faraday::Response.new(env)
    end
  end
end