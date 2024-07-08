# frozen_string_literal: true
require "rack"
require "json"

class IntegrationServer

  def self.respond_with(options = {})
    code = options.fetch(:code, 200)
    body = options.fetch(:body, "")
    headers = { "Content-Type" => "text/plain", "Content-Length" => body.size.to_s }.merge options.fetch(:headers, {})

    [code, headers, [body]]
  end

  Application = Rack::Builder.new do

    map "/" do
      run lambda { |env|
        IntegrationServer.respond_with :body => env["REQUEST_METHOD"].downcase
      }
    end

    map "/repeat" do
      run lambda { |env|
        # stupid way of extracting the value from a query string (e.g. "code=500") [dh, 2012-12-08]
        IntegrationServer.respond_with :body => env["rack.input"].read
      }
    end

    map "/404" do
      run lambda { |env|
        IntegrationServer.respond_with :code => 404, :body => env["rack.input"].read
      }
    end

    map "/timeout" do
      run lambda { |env|
        sleep 2
        IntegrationServer.respond_with :body => "timeout"
      }
    end

    map "/inspect_request" do
      run lambda { |env|
        body = {
          :soap_action  => env["HTTP_SOAPACTION"],
          :cookie       => env["HTTP_COOKIE"],
          :x_token      => env["HTTP_X_TOKEN"],
          :content_type => env["CONTENT_TYPE"]
        }

        IntegrationServer.respond_with :body => JSON.dump(body)
      }
    end

    map "/basic_auth" do
      use Rack::Auth::Basic, "basic-realm" do |username, password|
        username == "admin" && password == "secret"
      end

      run lambda { |env|
        IntegrationServer.respond_with :body => "basic-auth"
      }
    end

    map "/multipart" do
      run lambda { |env|
        boundary = 'mimepart_boundary'
        message = Mail.new
        xml_part = Mail::Part.new do
          content_type 'text/xml'
          body %{<?xml version='1.0' encoding='UTF-8'?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Header>response header</soapenv:Header>
  <soapenv:Body>response body</soapenv:Body>
</soapenv:Envelope>}
          # in Content-Type the start parameter is recommended (RFC 2387)
          content_id '<soap-request-body@soap>'
        end
        message.add_part xml_part

        message.add_file File.expand_path("../../../fixtures/gzip/message.gz", __FILE__)
        message.parts.last.content_location = 'message.gz'
        message.parts.last.content_id = 'attachment1'

        message.ready_to_send!
        message.body.set_sort_order [ "text/xml" ]
        message.body.encoded(message.content_transfer_encoding)

        IntegrationServer.respond_with({
          headers: { "Content-Type" => "multipart/related; boundary=\"#{message.body.boundary}\"; type=\"text/xml\"; start=\"#{xml_part.content_id}\"" },
          body: message.body.encoded(message.content_transfer_encoding)
        })
      }
    end

  end
end
