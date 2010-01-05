require "spec_helper"

describe Net::HTTP do
  before do
    @some_uri = URI "http://example.com"
    @another_uri = URI "http://example.org"
    @http = Net::HTTP.new @some_uri.host, @some_uri.port
  end

  describe "endpoint" do
    it "changes the address and port of a Net::HTTP object" do
      @http.address.should == @some_uri.host
      @http.port.should == @some_uri.port

      @http.endpoint @another_uri.host, @another_uri.port
      @http.address.should == @another_uri.host
      @http.port.should == @another_uri.port
    end
  end

  describe "ssl_client_auth" do
    it "accepts a Hash of options for SSL client authentication" do
      @http.cert.should be_nil
      @http.key.should be_nil
      @http.ca_file.should be_nil
      @http.verify_mode.should be_nil

      @http.ssl_client_auth :cert => "cert", :key => "key",
        :ca_file => "ca_file", :verify_mode => OpenSSL::SSL::VERIFY_PEER

      @http.cert.should == "cert"
      @http.key.should == "key"
      @http.ca_file.should == "ca_file"
      @http.verify_mode.should == OpenSSL::SSL::VERIFY_PEER
    end
  end

end
