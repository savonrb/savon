# frozen_string_literal: true
require "spec_helper"
require "integration/support/server"

RSpec.describe Savon::WSDLRequest do

  let(:globals)      { Savon::GlobalOptions.new }
  let(:http_connection) { Faraday::Connection.new }
  let(:ciphers)      { OpenSSL::Cipher.ciphers }

  def new_wsdl_request
    Savon::WSDLRequest.new(globals, http_connection)
  end

  describe "build" do
    it "returns an Faraday::Request" do
      wsdl_request = Savon::WSDLRequest.new(globals)
      result = wsdl_request.build
      expect(result).to be_an(Faraday::Connection)
    end

    describe "headers" do
      it "are set when specified" do
        globals.headers("Proxy-Authorization" => "Basic auth")
        configured_http_request = new_wsdl_request.build

        expect(configured_http_request.headers["Proxy-Authorization"]).to eq("Basic auth")
      end

      it "are not set otherwise" do
        configured_http_request = new_wsdl_request.build
        expect(configured_http_request.headers).to_not include("Proxy-Authorization")
      end
    end

    describe "proxy" do
      it "is set when specified" do
        globals.proxy("http://proxy.example.com")
        http_connection.expects(:proxy=).with("http://proxy.example.com")

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.expects(:proxy=).never
        new_wsdl_request.build
      end
    end

    describe "open timeout" do
      it "is set when specified" do
        globals.open_timeout(22)
        http_connection.options.expects(:open_timeout=).with(22)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.options.expects(:open_timeout=).never
        new_wsdl_request.build
      end
    end

    describe "read timeout" do
      it "is set when specified" do
        globals.read_timeout(33)
        http_connection.options.expects(:read_timeout=).with(33)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.options.expects(:read_timeout=).never
        new_wsdl_request.build
      end
    end

    describe "write timeout" do
      it "is set when specified" do
        globals.write_timeout(44)
        http_connection.options.expects(:write_timeout=).with(44)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.expects(:read_timeout=).never
        new_wsdl_request.build
      end
    end

    describe "ssl version" do
      it "is set when specified" do
        globals.ssl_version(:TLSv1)
        http_connection.ssl.expects(:version=).with(:TLSv1)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.ssl.expects(:version=).never
        new_wsdl_request.build
      end
    end

    describe "ssl min_version" do
      it "is set when specified" do
        globals.ssl_min_version(:TLS1_2)
        http_connection.ssl.expects(:min_version=).with(:TLS1_2)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.ssl.expects(:min_version=).never
        new_wsdl_request.build
      end
    end

    describe "ssl max_version" do
      it "is set when specified" do
        globals.ssl_max_version(:TLS1_2)
        http_connection.ssl.expects(:max_version=).with(:TLS1_2)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.ssl.expects(:max_version=).never
        new_wsdl_request.build
      end
    end

    describe "ssl verify mode" do
      it "is set when specified" do
        globals.ssl_verify_mode(:peer)
        http_connection.ssl.expects(:verify_mode=).with(:peer)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.ssl.expects(:verify_mode=).never
        new_wsdl_request.build
      end
    end

    describe "basic auth" do
      it "is set when specified" do
        globals.basic_auth("luke", "secret")
        http_connection.expects(:request).with(:authorization, :basic,"luke", "secret")

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.expects(:request).with{|args| args.include?(:basic)}.never
        new_wsdl_request.build
      end
    end

    describe "digest auth" do
      it "is set when specified" do
        globals.digest_auth("lea", "top-secret")
        http_connection.expects(:request).with(:digest, "lea", "top-secret")

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_connection.expects(:request).with{|args| args.include?(:digest)}.never
        new_wsdl_request.build
      end
    end

    describe "ntlm auth" do
      it 'tries to load ntlm when set' do
        globals.ntlm("han", "super-secret")
        new_wsdl_request.build
        expect(require 'rubyntlm').to be(false)
      end

      it "applies net-http-persistent when set" do
        globals.ntlm("han", "super-secret")
        http_connection.expects(:adapter).with{|params| params == :net_http_persistent}.at_least_once

        new_wsdl_request.build
      end

      it "does not apply net-http-persistent when not set" do
        http_connection.expects(:adapter).with(:net_http_persistent, pool_size: 5).never
        new_wsdl_request.build
      end
    end
  end

end

RSpec.describe Savon::SOAPRequest do

  let(:globals)      { Savon::GlobalOptions.new }
  let(:http_connection) { Faraday::Connection.new }
  let(:ciphers)      { OpenSSL::Cipher.ciphers }

  def new_soap_request
    Savon::SOAPRequest.new(globals, http_connection)
  end

  describe "build" do
    it "returns an Faraday::Request" do
      soap_request = Savon::SOAPRequest.new(globals)
      expect(soap_request.build).to be_an(Faraday::Connection)
    end

    describe "proxy" do
      it "is set when specified" do
        globals.proxy("http://proxy.example.com")
        http_connection.expects(:proxy=).with("http://proxy.example.com")

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_connection.expects(:proxy=).never
        new_soap_request.build
      end
    end

    describe "cookies" do
      it "sets the given cookies" do
        cookies = {
          'some-cookie': 'choc-chip',
          path: '/',
          HttpOnly: nil
        }

        http_connection.headers.expects(:[]=).at_least_once
        http_connection.headers.expects(:[]=).with('Cookie', 'some-cookie=choc-chip; path=/; HttpOnly').at_least_once
        new_soap_request.build(:cookies => cookies)
      end

      it "does not set the cookies if there are none" do
        http_connection.headers.expects(:[]=).at_least_once
        http_connection.expects(:[]=).with('Cookie').never
        new_soap_request.build
      end
    end

    describe "open timeout" do
      it "is set when specified" do
        globals.open_timeout(22)
        http_connection.options.expects(:open_timeout=).with(22)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_connection.options.expects(:open_timeout=).never
        new_soap_request.build
      end
    end

    describe "read timeout" do
      it "is set when specified" do
        globals.read_timeout(33)
        http_connection.options.expects(:read_timeout=).with(33)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_connection.options.expects(:read_timeout=).never
        new_soap_request.build
      end
    end

    describe "headers" do
      it "are set when specified" do
        globals.headers("X-Token" => "secret")
        configured_http_request = new_soap_request.build

        expect(configured_http_request.headers["X-Token"]).to eq("secret")
      end

      it "are not set otherwise" do
        configured_http_request = new_soap_request.build
        expect(configured_http_request.headers).to_not include("X-Token")
      end
    end

    describe "SOAPAction header" do
      it "is set and wrapped in parenthesis" do
        configured_http_request = new_soap_request.build(:soap_action => "findUser")
        soap_action = configured_http_request.headers["SOAPAction"]

        expect(soap_action).to eq(%("findUser"))
      end

      it "is not set when it's explicitely set to nil" do
        configured_http_request = new_soap_request.build(:soap_action => nil)
        expect(configured_http_request.headers).to_not include("SOAPAction")
      end

      it "is not set when there is already a SOAPAction value" do
        globals.headers("SOAPAction" => %("authenticate"))
        configured_http_request = new_soap_request.build(:soap_action => "findUser")
        soap_action = configured_http_request.headers["SOAPAction"]

        expect(soap_action).to eq(%("authenticate"))
      end
    end

    describe "Content-Type header" do
      it "defaults to SOAP 1.1 and UTF-8" do
        configured_http_request = new_soap_request.build
        content_type = configured_http_request.headers["Content-Type"]

        expect(content_type).to eq("text/xml;charset=UTF-8")
      end

      it "can be changed to SOAP 1.2 and any other encoding" do
        globals.soap_version(2)
        globals.encoding("ISO-8859-1")

        configured_http_request = new_soap_request.build
        content_type = configured_http_request.headers["Content-Type"]

        expect(content_type).to eq("application/soap+xml;charset=ISO-8859-1")
      end

      it "is not set when there is already a Content-Type value" do
        globals.headers("Content-Type" => "application/awesomeness;charset=UTF-3000")
        configured_http_request = new_soap_request.build(:soap_action => "findUser")
        content_type = configured_http_request.headers["Content-Type"]

        expect(content_type).to eq("application/awesomeness;charset=UTF-3000")
      end
    end

    describe "ssl version" do
      it "is set when specified" do
        globals.ssl_version(:TLSv1)
        http_connection.ssl.expects(:version=).with(:TLSv1)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_connection.ssl.expects(:version=).never
        new_soap_request.build
      end
    end

    describe "ssl verify mode" do
      it "is set when specified" do
        globals.ssl_verify_mode(:peer)
        http_connection.ssl.expects(:verify_mode=).with(:peer)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_connection.ssl.expects(:verify_mode=).never
        new_soap_request.build
      end
    end

    describe "basic auth" do
      it "is set when specified" do
        globals.basic_auth("luke", "secret")
        http_connection.expects(:request).with(:authorization, :basic, "luke", "secret")
        new_soap_request.build
      end

      it "is not set otherwise" do
        http_connection.expects(:request).with(:authorization, :basic, "luke", 'secret').never
        new_soap_request.build
      end
    end

    describe "digest auth" do
      it "is set when specified" do
        globals.digest_auth("lea", "top-secret")
        http_connection.expects(:request).with(:digest, "lea", "top-secret")

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_connection.expects(:request).with(:digest, "lea", 'top-secret').never
        new_soap_request.build
      end
    end

    describe "ntlm auth" do
      it "uses the net-http-persistent adapter in faraday" do
        globals.ntlm("han", "super-secret")
        http_connection.expects(:adapter).with(:net_http_persistent, {:pool_size => 5})
        new_soap_request.build
      end

      it "is not set otherwise" do
        http_connection.expects(:adapter).with(:net_http_persistent, {:pool_size => 5}).never
        new_soap_request.build
      end
    end
  end

end
