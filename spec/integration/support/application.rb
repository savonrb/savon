require "rack/builder"

class IntegrationServer

  def self.respond_with(body)
    [200, { "Content-Type" => "text/plain", "Content-Length" => body.size.to_s }, [body]]
  end

  Application = Rack::Builder.new do

    map "/" do
      run lambda { |env|
        IntegrationServer.respond_with env["REQUEST_METHOD"].downcase
      }
    end

    map "/repeat" do
      run lambda { |env|
        IntegrationServer.respond_with env["rack.input"].read
      }
    end

    map "/timeout" do
      run lambda { |env|
        sleep 2
        IntegrationServer.respond_with "timeout"
      }
    end

    map "/repeat-header" do
      run lambda { |env|
        IntegrationServer.respond_with env["HTTP_REPEAT_HEADER"]
      }
    end

    map "/inspect-header" do
      run lambda { |env|
        header_to_inspect = "HTTP_" + env["HTTP_INSPECT_HEADER"].upcase
        IntegrationServer.respond_with env[header_to_inspect]
      }
    end

    map "/basic-auth" do
      use Rack::Auth::Basic, "basic-realm" do |username, password|
        username == "admin" && password == "secret"
      end

      run lambda { |env|
        IntegrationServer.respond_with "basic-auth"
      }
    end

    map "/digest-auth" do
      unprotected_app = lambda { |env|
        IntegrationServer.respond_with "digest-auth"
      }

      realm = 'digest-realm'
      app = Rack::Auth::Digest::MD5.new(unprotected_app) do |username|
        username == 'admin' ? Digest::MD5.hexdigest("admin:#{realm}:secret") : nil
      end
      app.realm = realm
      app.opaque = 'this-should-be-secret'
      app.passwords_hashed = true

      run app
    end

  end
end
