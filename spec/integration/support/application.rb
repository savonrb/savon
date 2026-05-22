# frozen_string_literal: true

require "rack"
require "json"
require "digest/md5"
require "net/ntlm"
require "openssl"

class IntegrationServer
  def self.respond_with(options = {})
    code = options.fetch(:code, 200)
    body = options.fetch(:body, "")
    headers = { "Content-Type" => "text/plain", "Content-Length" => body.size.to_s }.merge options.fetch(:headers, {})

    [code, headers, [body]]
  end

  # Tiny Digest auth endpoint for faraday-digestauth.
  #
  # Digest is HTTP challenge/response auth: the server sends a nonce, and the
  # client answers with a hash of the credentials plus request details. Rack 3
  # no longer ships Rack::Auth::Digest, so this keeps only the qop=auth path
  # used by the gem. The fixed nonce is fine here because each spec makes a
  # fresh challenge/response round trip.
  class DigestAuthEndpoint
    REALM = "savon-test"
    NONCE = "savon-test-nonce"
    USER  = "admin"
    PASS  = "secret"

    def call(env)
      auth = env["HTTP_AUTHORIZATION"]
      return unauthorized unless auth&.start_with?("Digest ")

      params = parse_authorization(auth)

      if params["username"] == USER && params["nonce"] == NONCE && params["response"] == expected_response(params)
        IntegrationServer.respond_with(body: "digest-auth-ok")
      else
        unauthorized
      end
    end

    private

    def parse_authorization(auth)
      auth[7..].scan(/(\w+)="?([^",]*)"?/).to_h
    end

    def expected_response(params)
      return unless params["qop"] == "auth" && params["cnonce"] && params["nc"]

      # RFC 7616 sections 3.4.1-3.4.3 define this response hash for qop=auth.
      # We leave `algorithm` out of the challenge; per RFC 7616, that means MD5.
      # faraday-digestauth sends the same shape.
      #   HA1 = MD5(username:realm:password)
      #   HA2 = MD5(method:uri)
      #   response = MD5(HA1:nonce:nc:cnonce:qop:HA2)
      ha1 = Digest::MD5.hexdigest("#{USER}:#{REALM}:#{PASS}")
      ha2 = Digest::MD5.hexdigest("POST:#{params['uri']}")
      Digest::MD5.hexdigest("#{ha1}:#{NONCE}:#{params['nc']}:#{params['cnonce']}:auth:#{ha2}")
    end

    def unauthorized
      [
        401,
        { "WWW-Authenticate" => "Digest realm=\"#{REALM}\", nonce=\"#{NONCE}\", qop=\"auth\"",
          "Content-Length"   => "0" },
        []
      ]
    end
  end

  # Small NTLM endpoint for faraday-ntlm_auth.
  # NTLM is a three-message handshake:
  #   * Type1 from the client
  #   * Type2 challenge from the server
  #   * Type3 proof from the client
  #
  # The Type3 response only verifies against the Type2 challenge that produced it,
  # so this endpoint stores the challenge between requests. Rack/Puma do not expose
  # a stable connection id here but REMOTE_ADDR should be enough for these specs.
  class NtlmAuthEndpoint
    USER   = "admin"
    PASS   = "secret"
    DOMAIN = ""

    def initialize
      @challenges = {}
      @mutex = Mutex.new
    end

    def call(env)
      auth = env["HTTP_AUTHORIZATION"]
      return unauthorized unless auth&.start_with?("NTLM ")

      msg = Net::NTLM::Message.decode64(auth[5..])

      case msg
      when Net::NTLM::Message::Type1
        challenge_response(env)
      when Net::NTLM::Message::Type3
        final_response(env, msg)
      else
        unauthorized
      end
    end

    private

    def challenge_response(env)
      challenge_bytes = OpenSSL::Random.random_bytes(8)
      @mutex.synchronize do
        @challenges[connection_key(env)] = challenge_bytes
      end

      [401, { "WWW-Authenticate" => "NTLM #{type2_challenge(challenge_bytes)}",
              "Content-Length"   => "0" }, []]
    end

    def final_response(env, msg)
      challenge_bytes = @mutex.synchronize { @challenges.delete(connection_key(env)) }
      user = Net::NTLM::EncodeUtil.decode_utf16le(msg.user)
      domain = Net::NTLM::EncodeUtil.decode_utf16le(msg.domain)

      if challenge_bytes && user == USER && domain == DOMAIN && msg.password?(PASS, challenge_bytes)
        IntegrationServer.respond_with(body: "ntlm-auth-ok")
      else
        unauthorized
      end
    end

    def type2_challenge(challenge_bytes)
      type2 = Net::NTLM::Message::Type2.new

      # NTLM2_KEY tells the client to use NTLMv2 session security for its Type3 response.
      type2[:flag].value = Net::NTLM::DEFAULT_FLAGS[:TYPE2] |
                           Net::NTLM::FLAGS[:NTLM] |
                           Net::NTLM::FLAGS[:NTLM2_KEY]

      # `Q` unpacks 8 bytes as an unsigned 64-bit integer.
      type2[:challenge].value = challenge_bytes.unpack1("Q")

      # The Type2 binary header contains offset/length pairs that tell the client where each
      # field lives in the message blob. rubyntlm 0.6.5 miscalculates these offsets when
      # target_info is not set, so we activate it with an empty buffer. The field carries
      # no data but forces the serializer to compute the offsets correctly.
      type2[:target_info].active = true

      type2.encode64
    end

    def connection_key(env)
      env["REMOTE_ADDR"]
    end

    def unauthorized
      [401, { "WWW-Authenticate" => "NTLM", "Content-Length" => "0" }, []]
    end
  end

  DIGEST_AUTH_ENDPOINT = DigestAuthEndpoint.new
  NTLM_AUTH_ENDPOINT = NtlmAuthEndpoint.new

  Application = Rack::Builder.new do
    map "/" do
      run lambda { |env|
        IntegrationServer.respond_with body: env["REQUEST_METHOD"].downcase
      }
    end

    map "/repeat" do
      run lambda { |env|
        IntegrationServer.respond_with body: env["rack.input"].read
      }
    end

    map "/404" do
      run lambda { |env|
        IntegrationServer.respond_with code: 404, body: env["rack.input"].read
      }
    end

    map "/timeout" do
      run lambda { |_env|
        sleep 2
        IntegrationServer.respond_with body: "timeout"
      }
    end

    map "/inspect_request" do
      run lambda { |env|
        request_body = env["rack.input"].read
        body = {
          soap_action: env["HTTP_SOAPACTION"],
          cookie: env["HTTP_COOKIE"],
          x_token: env["HTTP_X_TOKEN"],
          content_type: env["CONTENT_TYPE"],
          content_length: env["CONTENT_LENGTH"],
          body_bytesize: request_body.bytesize.to_s
        }

        IntegrationServer.respond_with body: JSON.dump(body)
      }
    end

    map "/basic_auth" do
      use Rack::Auth::Basic, "basic-realm" do |username, password|
        username == "admin" && password == "secret"
      end

      run lambda { |_env|
        IntegrationServer.respond_with body: "basic-auth"
      }
    end

    map "/authentication.wsdl" do
      run lambda { |_env|
        IntegrationServer.respond_with(
          body: Fixture.wsdl(:authentication),
          headers: { "Content-Type" => "text/xml" }
        )
      }
    end

    # 307 keeps the redirect as POST with the original body.
    # Using 302 with Faraday's follow_redirects middleware
    # rewrites POST to GET and drops the body.
    map "/redirect" do
      run lambda { |env|
        env["rack.input"].read
        location = "http://#{env['HTTP_HOST']}/repeat"
        [307, { "Location" => location, "Content-Length" => "0" }, []]
      }
    end

    map "/digest_auth" do
      run IntegrationServer::DIGEST_AUTH_ENDPOINT
    end

    map "/ntlm_auth" do
      run IntegrationServer::NTLM_AUTH_ENDPOINT
    end

    map "/multipart" do
      run lambda { |_env|
        message = Mail.new
        xml_part = Mail::Part.new do
          content_type 'text/xml'
          body %(<?xml version='1.0' encoding='UTF-8'?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Header>response header</soapenv:Header>
  <soapenv:Body>response body</soapenv:Body>
</soapenv:Envelope>)
          # Give the XML part a Content-ID so the `start` parameter
          # (set on the Content-Type header below) can reference it
          # as the root part.
          content_id '<soap-request-body@soap>'
        end
        message.add_part xml_part

        message.add_file File.expand_path('../../fixtures/gzip/message.gz', __dir__)
        message.parts.last.content_location = 'message.gz'
        message.parts.last.content_id = 'attachment1'

        message.ready_to_send!
        message.body.set_sort_order ["text/xml"]
        message.body.encoded(message.content_transfer_encoding)

        IntegrationServer.respond_with({
          headers: { "Content-Type" => %(multipart/related; boundary="#{message.body.boundary}"; type="text/xml"; start="#{xml_part.content_id}") },
          body: message.body.encoded(message.content_transfer_encoding)
        })
      }
    end
  end
end
