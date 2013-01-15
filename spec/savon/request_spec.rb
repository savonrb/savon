require "spec_helper"
require "integration/support/server"

describe Savon::WSDLRequest do

  let(:globals)      { Savon::GlobalOptions.new }
  let(:http_request) { HTTPI::Request.new }

  def new_wsdl_request
    Savon::WSDLRequest.new(globals, http_request)
  end

  describe "#build" do
    it "returns an HTTPI::Request" do
      wsdl_request = Savon::WSDLRequest.new(globals)
      expect(wsdl_request.build).to be_an(HTTPI::Request)
    end

    describe "open timeout" do
      it "is set when specified" do
        globals.open_timeout(22)
        http_request.expects(:open_timeout=).with(22)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_request.expects(:open_timeout=).never
        new_wsdl_request.build
      end
    end

    describe "read timeout" do
      it "is set when specified" do
        globals.read_timeout(33)
        http_request.expects(:read_timeout=).with(33)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_request.expects(:read_timeout=).never
        new_wsdl_request.build
      end
    end

    describe "ssl version" do
      it "is set when specified" do
        globals.ssl_version(:SSLv3)
        http_request.auth.ssl.expects(:ssl_version=).with(:SSLv3)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:ssl_version=).never
        new_wsdl_request.build
      end
    end

    describe "ssl verify mode" do
      it "is set when specified" do
        globals.ssl_verify_mode(:none)
        http_request.auth.ssl.expects(:verify_mode=).with(:none)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:verify_mode=).never
        new_wsdl_request.build
      end
    end

    describe "ssl cert key file" do
      it "is set when specified" do
        cert_key = File.expand_path("../../fixtures/ssl/client_key.pem", __FILE__)
        globals.ssl_cert_key_file(cert_key)
        http_request.auth.ssl.expects(:cert_key_file=).with(cert_key)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:cert_key_file=).never
        new_wsdl_request.build
      end
    end

    describe "ssl cert key password" do
      it "is set when specified" do
        the_pass = "secure-password!42"
        globals.ssl_cert_key_password(the_pass)
        http_request.auth.ssl.expects(:cert_key_password=).with(the_pass)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:cert_key_password=).never
        new_wsdl_request.build
      end
    end
    
    describe "ssl cert file" do
      it "is set when specified" do
        cert = File.expand_path("../../fixtures/ssl/client_cert.pem", __FILE__)
        globals.ssl_cert_file(cert)
        http_request.auth.ssl.expects(:cert_file=).with(cert)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:cert_file=).never
        new_wsdl_request.build
      end
    end

    describe "ssl ca cert file" do
      it "is set when specified" do
        ca_cert = File.expand_path("../../fixtures/ssl/client_cert.pem", __FILE__)
        globals.ssl_ca_cert_file(ca_cert)
        http_request.auth.ssl.expects(:ca_cert_file=).with(ca_cert)

        new_wsdl_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:ca_cert_file=).never
        new_wsdl_request.build
      end
    end
  end

end

describe Savon::SOAPRequest do

  let(:globals)      { Savon::GlobalOptions.new }
  let(:http_request) { HTTPI::Request.new }

  def new_soap_request
    Savon::SOAPRequest.new(globals, http_request)
  end

  describe "#build" do
    it "returns an HTTPI::Request" do
      soap_request = Savon::SOAPRequest.new(globals)
      expect(soap_request.build).to be_an(HTTPI::Request)
    end

    describe "proxy" do
      it "is set when specified" do
        globals.proxy("http://proxy.example.com")
        http_request.expects(:proxy=).with("http://proxy.example.com")

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.expects(:proxy=).never
        new_soap_request.build
      end
    end

    describe "cookies" do
      it "sets the cookies from the last response" do
        headers  = { "Set-Cookie" => "some-cookie=choc-chip; Path=/; HttpOnly" }
        response = HTTPI::Response.new(200, headers, "")
        globals.last_response(response)

        http_request.expects(:set_cookies).with(response)
        new_soap_request.build
      end

      it "does not set the cookies if there is no last response" do
        http_request.expects(:set_cookies).never
        new_soap_request.build
      end
    end

    describe "open timeout" do
      it "is set when specified" do
        globals.open_timeout(22)
        http_request.expects(:open_timeout=).with(22)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.expects(:open_timeout=).never
        new_soap_request.build
      end
    end

    describe "read timeout" do
      it "is set when specified" do
        globals.read_timeout(33)
        http_request.expects(:read_timeout=).with(33)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.expects(:read_timeout=).never
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
        configured_http_request = new_soap_request.build("findUser")
        soap_action = configured_http_request.headers["SOAPAction"]

        expect(soap_action).to eq(%("findUser"))
      end

      it "is not set when it's explicitely set to nil" do
        configured_http_request = new_soap_request.build(nil)
        expect(configured_http_request.headers).to_not include("SOAPAction")
      end

      it "is not set when there is already a SOAPAction value" do
        globals.headers("SOAPAction" => %("authenticate"))
        configured_http_request = new_soap_request.build("findUser")
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
        configured_http_request = new_soap_request.build("findUser")
        content_type = configured_http_request.headers["Content-Type"]

        expect(content_type).to eq("application/awesomeness;charset=UTF-3000")
      end
    end

    describe "ssl version" do
      it "is set when specified" do
        globals.ssl_version(:SSLv3)
        http_request.auth.ssl.expects(:ssl_version=).with(:SSLv3)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:ssl_version=).never
        new_soap_request.build
      end
    end

    describe "ssl verify mode" do
      it "is set when specified" do
        globals.ssl_verify_mode(:none)
        http_request.auth.ssl.expects(:verify_mode=).with(:none)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:verify_mode=).never
        new_soap_request.build
      end
    end

    describe "ssl cert key file" do
      it "is set when specified" do
        cert_key = File.expand_path("../../fixtures/ssl/client_key.pem", __FILE__)
        globals.ssl_cert_key_file(cert_key)
        http_request.auth.ssl.expects(:cert_key_file=).with(cert_key)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:cert_key_file=).never
        new_soap_request.build
      end
    end
    
    describe "ssl cert key password" do
      it "is set when specified" do
        the_pass = "secure-password!42"
        globals.ssl_cert_key_password(the_pass)
        http_request.auth.ssl.expects(:cert_key_password=).with(the_pass)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:cert_key_password=).never
        new_soap_request.build
      end
    end

    describe "ssl cert file" do
      it "is set when specified" do
        cert = File.expand_path("../../fixtures/ssl/client_cert.pem", __FILE__)
        globals.ssl_cert_file(cert)
        http_request.auth.ssl.expects(:cert_file=).with(cert)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:cert_file=).never
        new_soap_request.build
      end
    end

    describe "ssl ca cert file" do
      it "is set when specified" do
        ca_cert = File.expand_path("../../fixtures/ssl/client_cert.pem", __FILE__)
        globals.ssl_ca_cert_file(ca_cert)
        http_request.auth.ssl.expects(:ca_cert_file=).with(ca_cert)

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.auth.ssl.expects(:ca_cert_file=).never
        new_soap_request.build
      end
    end

    describe "basic auth" do
      it "is set when specified" do
        globals.basic_auth("luke", "secret")
        http_request.auth.expects(:basic).with("luke", "secret")

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.auth.expects(:basic).never
        new_soap_request.build
      end
    end

    describe "digest auth" do
      it "is set when specified" do
        globals.digest_auth("lea", "top-secret")
        http_request.auth.expects(:digest).with("lea", "top-secret")

        new_soap_request.build
      end

      it "is not set otherwise" do
        http_request.auth.expects(:digest).never
        new_soap_request.build
      end
    end
  end

end
