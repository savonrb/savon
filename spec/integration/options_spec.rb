require "spec_helper"
require "integration/support/server"

describe "NewClient Options" do

  context "global :open_timeout" do
    it "makes the client timeout after n seconds" do
      non_routable_ip = "http://10.255.255.1"
      client = new_client(:endpoint => non_routable_ip, :open_timeout => 1)

      # TODO: make HTTPI tag timeout errors, then depend on HTTPI::TimeoutError instead of a specific client error [dh, 2012-12-08]
      expect { client.call(:authenticate) }.to raise_error(HTTPClient::ConnectTimeoutError)
    end
  end

  context "global :read timeout" do
    before do
      @server = IntegrationServer.run
    end

    after do
      @server.stop
    end

    it "makes the client timeout after n seconds" do
      timeout_url = @server.url + "/timeout"
      client = new_client(:endpoint => timeout_url, :open_timeout => 1, :read_timeout => 1)

      expect { client.call(:authenticate) }.to raise_error(HTTPClient::ReceiveTimeoutError)
    end
  end

  def new_client(options = {})
    Savon.new_client(Fixture.wsdl(:authentication), options)
  end

end
