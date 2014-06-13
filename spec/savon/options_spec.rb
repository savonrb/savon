require "spec_helper"
require "integration/support/server"
require "json"
require "ostruct"
require "logger"

describe "Options" do

  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  context "global: endpoint and namespace" do
    it "sets the SOAP endpoint to use to allow requests without a WSDL document" do
      client = new_client_without_wsdl(:endpoint => @server.url(:repeat), :namespace => "http://v1.example.com")
      response = client.call(:authenticate)

      # the default namespace identifier is :wsdl and contains the namespace option
      expect(response.http.body).to include('xmlns:wsdl="http://v1.example.com"')

      # the default namespace applies to the message tag
      expect(response.http.body).to include('<wsdl:authenticate>')
    end
  end

  context "global :namespace_identifier" do
    it "changes the default namespace identifier" do
      client = new_client(:endpoint => @server.url(:repeat), :namespace_identifier => :lol)
      response = client.call(:authenticate)

      expect(response.http.body).to include('xmlns:lol="http://v1_0.ws.auth.order.example.com/"')
      expect(response.http.body).to include("<lol:authenticate></lol:authenticate>")
    end

    it "ignores namespace identifier if it is nil" do
      client = new_client(:endpoint => @server.url(:repeat), :namespace_identifier => nil)
      response = client.call(:authenticate, :message => {:user => 'foo'})

      expect(response.http.body).to include('xmlns="http://v1_0.ws.auth.order.example.com/"')
      expect(response.http.body).to include("<authenticate><user>foo</user></authenticate>")
    end
  end

  context "global: :no_message_tag" do
    it "omits the 'message tag' encapsulation step" do
      client = new_client(:endpoint => @server.url(:repeat), :no_message_tag => true,
                          :wsdl => Fixture.wsdl(:no_message_tag))
      msg = {'extLoginData' => {'Login' => 'test.user', 'Password' => 'secret', 'FacilityID' => 1,
               'ThreePLKey' => '{XXXX-XXXX-XXXX-XXXX}', 'ThreePLID' => 1},
             'Items' => ['Item' => {'SKU' => '001002003A', 'CustomerID' => 1,
              'InventoryMethod' => 'FIFO', 'UPC' => '001002003A'}]}
      response = client.call(:create_items, :message => msg)

      expect(response.http.body.scan(/<tns:extLoginData>/).count).to eq(1)
    end

    it "includes the 'message tag' encapsulation step" do
      # This test is probably just exposing a bug while the previous
      # test is using a workaround fix.
      # That is just a guess though. I don't really have to properly debug the WSDL parser.
      client = new_client(:endpoint => @server.url(:repeat), :no_message_tag => false,
                          :wsdl => Fixture.wsdl(:no_message_tag))
      msg = {'extLoginData' => {'Login' => 'test.user', 'Password' => 'secret', 'FacilityID' => 1,
               'ThreePLKey' => '{XXXX-XXXX-XXXX-XXXX}', 'ThreePLID' => 1},
             'Items' => ['Item' => {'SKU' => '001002003A', 'CustomerID' => 1,
              'InventoryMethod' => 'FIFO', 'UPC' => '001002003A'}]}
      response = client.call(:create_items, :message => msg)

      expect(response.http.body.scan(/<tns:extLoginData>/).count).to eq(2)
    end
  end

  context "global :namespaces" do
    it "adds additional namespaces to the SOAP envelope" do
      namespaces = { "xmlns:whatever" => "http://whatever.example.com" }
      client = new_client(:endpoint => @server.url(:repeat), :namespaces => namespaces)
      response = client.call(:authenticate)

      expect(response.http.body).to include('xmlns:whatever="http://whatever.example.com"')
    end
  end

  context "global :proxy" do
    it "sets the proxy server to use" do
      proxy_url = "http://example.com"
      client = new_client(:endpoint => @server.url, :proxy => proxy_url)

      # TODO: find a way to integration test this [dh, 2012-12-08]
      HTTPI::Request.any_instance.expects(:proxy=).with(proxy_url)

      response = client.call(:authenticate)
    end
  end

  context "global :headers" do
    it "sets the HTTP headers for the next request" do
      client = new_client(:endpoint => @server.url(:inspect_request), :headers => { "X-Token" => "secret" })

      response = client.call(:authenticate)
      x_token  = inspect_request(response).x_token

      expect(x_token).to eq("secret")
    end
  end

  context "global :open_timeout" do
    it "makes the client timeout after n seconds" do
      non_routable_ip = "http://192.0.2.0"
      client = new_client(:endpoint => non_routable_ip, :open_timeout => 0.1)

      expect { client.call(:authenticate) }.to raise_error { |error|
        host_unreachable = error.kind_of? Errno::EHOSTUNREACH
        net_unreachable = error.kind_of? Errno::ENETUNREACH
        socket_err = error.kind_of? SocketError
        if host_unreachable || net_unreachable || socket_err
          warn "Warning: looks like your network may be down?!\n" +
               "-> skipping spec at #{__FILE__}:#{__LINE__}"
        else
          # TODO: make HTTPI tag timeout errors, then depend on HTTPI::TimeoutError
          #       instead of a specific client error [dh, 2012-12-08]
          expect(error).to be_an(HTTPClient::ConnectTimeoutError)
        end
      }
    end
  end

  context "global :read_timeout" do
    it "makes the client timeout after n seconds" do
      client = new_client(:endpoint => @server.url(:timeout), :open_timeout => 0.1, :read_timeout => 0.1)

      expect { client.call(:authenticate) }.
        to raise_error(HTTPClient::ReceiveTimeoutError)
    end
  end

  context "global :encoding" do
    it "changes the XML instruction" do
      client = new_client(:endpoint => @server.url(:repeat), :encoding => "ISO-8859-1")
      response = client.call(:authenticate)

      expect(response.http.body).to match(/<\?xml version="1\.0" encoding="ISO-8859-1"\?>/)
    end

    it "changes the Content-Type header" do
      client = new_client(:endpoint => @server.url(:inspect_request), :encoding => "ISO-8859-1")

      response = client.call(:authenticate)
      content_type = inspect_request(response).content_type
      expect(content_type).to eq("text/xml;charset=ISO-8859-1")
    end
  end

  context "global :soap_header" do
    it "accepts a Hash of SOAP header information" do
      client = new_client(:endpoint => @server.url(:repeat), :soap_header => { :auth_token => "secret" })
      response = client.call(:authenticate)

      expect(response.http.body).to include("<env:Header><authToken>secret</authToken></env:Header>")
    end

    it "accepts anything other than a String and calls #to_s on it" do
      to_s_header = Class.new {
        def to_s
          "to_s_header"
        end
      }.new

      client = new_client(:endpoint => @server.url(:repeat), :soap_header => to_s_header)
      response = client.call(:authenticate)

      expect(response.http.body).to include("<env:Header>to_s_header</env:Header>")
    end
  end

  context "global :element_form_default" do
    it "specifies whether elements should be :qualified or :unqualified" do
      # qualified
      client = new_client(:endpoint => @server.url(:repeat), :element_form_default => :qualified)

      response = client.call(:authenticate, :message => { :user => "luke", :password => "secret" })
      expect(response.http.body).to include("<tns:user>luke</tns:user>")
      expect(response.http.body).to include("<tns:password>secret</tns:password>")

      # unqualified
      client = new_client(:endpoint => @server.url(:repeat), :element_form_default => :unqualified)

      response = client.call(:authenticate, :message => { :user => "lea", :password => "top-secret" })
      expect(response.http.body).to include("<user>lea</user>")
      expect(response.http.body).to include("<password>top-secret</password>")
    end
  end

  context "global :env_namespace" do
    it "when set, replaces the default namespace identifier for the SOAP envelope" do
      client = new_client(:endpoint => @server.url(:repeat), :env_namespace => "soapenv")
      response = client.call(:authenticate)

      expect(response.http.body).to include("<soapenv:Envelope")
    end

    it "when not set, Savon defaults to use :env as the namespace identifier for the SOAP envelope" do
      client = new_client(:endpoint => @server.url(:repeat))
      response = client.call(:authenticate)

      expect(response.http.body).to include("<env:Envelope")
    end
  end

  context "global :soap_version" do
    it "it uses the correct SOAP 1.1 namespace" do
      client = new_client(:endpoint => @server.url(:repeat), :soap_version => 1)
      response = client.call(:authenticate)

      expect(response.http.body).to include('xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"')
    end

    it "it uses the correct SOAP 1.2 namespace" do
      client = new_client(:endpoint => @server.url(:repeat), :soap_version => 2)
      response = client.call(:authenticate)

      expect(response.http.body).to include('xmlns:env="http://www.w3.org/2003/05/soap-envelope"')
    end
  end

  context "global: raise_errors" do
    it "when true, instructs Savon to raise SOAP fault errors" do
      client = new_client(:endpoint => @server.url(:repeat), :raise_errors => true)

      expect { client.call(:authenticate, :xml => Fixture.response(:soap_fault)) }.
        to raise_error(Savon::SOAPFault)

      begin
        client.call(:authenticate, :xml => Fixture.response(:soap_fault))
      rescue Savon::SOAPFault => soap_fault
        # check whether the configured nori instance is used by the soap fault
        expect(soap_fault.to_hash[:fault][:faultcode]).to eq("soap:Server")
      end
    end

    it "when true, instructs Savon to raise HTTP errors" do
      client = new_client(:endpoint => @server.url(404), :raise_errors => true)
      expect { client.call(:authenticate) }.to raise_error(Savon::HTTPError)
    end

    it "when false, instructs Savon to not raise SOAP fault errors" do
      client = new_client(:endpoint => @server.url(:repeat), :raise_errors => false)
      response = client.call(:authenticate, :xml => Fixture.response(:soap_fault))

      expect(response).to_not be_successful
      expect(response).to be_a_soap_fault
    end

    it "when false, instructs Savon to not raise HTTP errors" do
      client = new_client(:endpoint => @server.url(404), :raise_errors => false)
      response = client.call(:authenticate)

      expect(response).to_not be_successful
      expect(response).to be_a_http_error
    end
  end

  context "global :log" do
    it "instructs Savon not to log SOAP requests and responses" do
      stdout = mock_stdout {
        client = new_client(:endpoint => @server.url, :log => false)
        client.call(:authenticate)
      }

      expect(stdout.string).to be_empty
    end

    it "silences HTTPI as well" do
      HTTPI.expects(:log=).with(false)
      new_client(:log => false)
    end

    it "instructs Savon to log SOAP requests and responses" do
      stdout = mock_stdout do
        client = new_client(:endpoint => @server.url, :log => true)
        client.call(:authenticate)
      end

      expect(stdout.string).to include("INFO -- : SOAP request")
    end

    it "turns HTTPI logging back on as well" do
      HTTPI.expects(:log=).with(true)
      new_client(:log => true)
    end
  end

  context "global :logger" do
    it "defaults to an instance of Ruby's standard Logger" do
      logger = new_client.globals[:logger]
      expect(logger).to be_a(Logger)
    end

    it "allows a custom logger to be set" do
      custom_logger = Logger.new($stdout)

      client = new_client(:logger => custom_logger, :log => true)
      logger = client.globals[:logger]

      expect(logger).to eq(custom_logger)
    end
  end

  context "global :log_level" do
    it "allows changing the Logger's log level to :debug" do
      client = new_client(:log_level => :debug)
      level = client.globals[:logger].level

      expect(level).to eq(0)
    end

    it "allows changing the Logger's log level to :info" do
      client = new_client(:log_level => :info)
      level = client.globals[:logger].level

      expect(level).to eq(1)
    end

    it "allows changing the Logger's log level to :warn" do
      client = new_client(:log_level => :warn)
      level = client.globals[:logger].level

      expect(level).to eq(2)
    end

    it "allows changing the Logger's log level to :error" do
      client = new_client(:log_level => :error)
      level = client.globals[:logger].level

      expect(level).to eq(3)
    end

    it "allows changing the Logger's log level to :fatal" do
      client = new_client(:log_level => :fatal)
      level = client.globals[:logger].level

      expect(level).to eq(4)
    end

    it "raises when the given level is not valid" do
      expect { new_client(:log_level => :invalid) }.
        to raise_error(ArgumentError, /Invalid log level: :invalid/)
    end
  end

  context "global :ssl_version" do
    it "sets the SSL version to use" do
      HTTPI::Auth::SSL.any_instance.expects(:ssl_version=).with(:SSLv3).twice

      client = new_client(:endpoint => @server.url, :ssl_version => :SSLv3)
      client.call(:authenticate)
    end
  end

  context "global :ssl_verify_mode" do
    it "sets the verify mode to use" do
      HTTPI::Auth::SSL.any_instance.expects(:verify_mode=).with(:none).twice

      client = new_client(:endpoint => @server.url, :ssl_verify_mode => :none)
      client.call(:authenticate)
    end
  end

  context "global :ssl_cert_key_file" do
    it "sets the cert key file to use" do
      cert_key = File.expand_path("../../fixtures/ssl/client_key.pem", __FILE__)
      HTTPI::Auth::SSL.any_instance.expects(:cert_key_file=).with(cert_key).twice

      client = new_client(:endpoint => @server.url, :ssl_cert_key_file => cert_key)
      client.call(:authenticate)
    end
  end

  context "global :ssl_cert_key_password" do
    it "sets the encrypted cert key file password to use" do
      cert_key = File.expand_path("../../fixtures/ssl/client_encrypted_key.pem", __FILE__)
      cert_key_pass = "secure-password!42"
      HTTPI::Auth::SSL.any_instance.expects(:cert_key_file=).with(cert_key).twice
      HTTPI::Auth::SSL.any_instance.expects(:cert_key_password=).with(cert_key_pass).twice

      client = new_client(:endpoint => @server.url, :ssl_cert_key_file => cert_key, :ssl_cert_key_password => cert_key_pass)
      client.call(:authenticate)
    end

  end

  context "global :ssl_cert_file" do
    it "sets the cert file to use" do
      cert = File.expand_path("../../fixtures/ssl/client_cert.pem", __FILE__)
      HTTPI::Auth::SSL.any_instance.expects(:cert_file=).with(cert).twice

      client = new_client(:endpoint => @server.url, :ssl_cert_file => cert)
      client.call(:authenticate)
    end
  end

  context "global :ssl_ca_cert_file" do
    it "sets the ca cert file to use" do
      ca_cert = File.expand_path("../../fixtures/ssl/client_cert.pem", __FILE__)
      HTTPI::Auth::SSL.any_instance.expects(:ca_cert_file=).with(ca_cert).twice

      client = new_client(:endpoint => @server.url, :ssl_ca_cert_file => ca_cert)
      client.call(:authenticate)
    end
  end

  context "global :basic_auth" do
    it "sets the basic auth credentials" do
      client = new_client(:endpoint => @server.url(:basic_auth), :basic_auth => ["admin", "secret"])
      response = client.call(:authenticate)

      expect(response.http.body).to eq("basic-auth")
    end
  end

  context "global :digest_auth" do
    it "sets the digest auth credentials" do
      client = new_client(:endpoint => @server.url(:digest_auth), :digest_auth => ["admin", "secret"])
      response = client.call(:authenticate)

      expect(response.http.body).to eq("digest-auth")
    end
  end

  context "global :ntlm" do
    it "sets the ntlm credentials to use" do
      credentials = ["admin", "secret"]
      client = new_client(:endpoint => @server.url, :ntlm => credentials)

      # TODO: find a way to integration test this. including an entire ntlm
      # server implementation seems a bit over the top though.
      HTTPI::Auth::Config.any_instance.expects(:ntlm).with(*credentials)

      response = client.call(:authenticate)
    end
  end

  context "global :filters" do
    it "filters a list of XML tags from logged SOAP messages" do
      silence_stdout do
        client = new_client(:endpoint => @server.url(:repeat), :log => true)

        client.globals[:filters] << :password

        # filter out logs we're not interested in
        client.globals[:logger].expects(:info).at_least_once

        # check whether the password is filtered
        client.globals[:logger].expects(:debug).with { |message|
          message.include? "<password>***FILTERED***</password>"
        }.twice

        message = { :username => "luke", :password => "secret" }
        client.call(:authenticate, :message => message)
      end
    end
  end

  context "global :pretty_print_xml" do
    it "is a nice but expensive way to debug XML messages" do
      silence_stdout do
        client = new_client(:endpoint => @server.url(:repeat), :pretty_print_xml => true, :log => true)

        # filter out logs we're not interested in
        client.globals[:logger].expects(:info).at_least_once

        # check whether the message is pretty printed
        client.globals[:logger].expects(:debug).with { |message|
          envelope    = message =~ /\n<env:Envelope/
          body        = message =~ /\n  <env:Body>/
          message_tag = message =~ /\n    <tns:authenticate\/>/

          envelope && body && message_tag
        }.twice

        client.call(:authenticate)
      end
    end
  end

  context ":wsse_auth" do
    let(:username) { "luke" }
    let(:password) { "secret" }
    let(:request) { response.http.body }

    context "without digest" do
      shared_examples "WSSE basic auth" do
        it "adds WSSE basic auth information to the request" do
          # the header and wsse security node
          wsse_namespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
          expect(request).to include("<env:Header><wsse:Security xmlns:wsse=\"#{wsse_namespace}\">")

          # split up to prevent problems with unordered Hash attributes in 1.8 [dh, 2012-12-13]
          expect(request).to include("<wsse:UsernameToken")
          expect(request).to include("wsu:Id=\"UsernameToken-1\"")
          expect(request).to include("xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\"")

          # the username and password node with type attribute
          expect(request).to include("<wsse:Username>#{username}</wsse:Username>")
          password_text = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"
          expect(request).to include("<wsse:Password Type=\"#{password_text}\">#{password}</wsse:Password>")
        end
      end

      context "global" do
        let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_auth => [username, password]) }
        let(:response) { client.call(:authenticate) }
        include_examples "WSSE basic auth"
      end

      context "local" do
        let(:client) { new_client(:endpoint => @server.url(:repeat)) }
        let(:response) do
          client.call(:authenticate) do |locals|
            locals.wsse_auth(username, password)
          end
        end
        include_examples "WSSE basic auth"
      end
    end

    context "with digest" do
      shared_examples "WSSE digest auth" do
        it "adds WSSE digest auth information to the request" do
          # the header and wsse security node
          wsse_namespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
          expect(request).to include("<env:Header><wsse:Security xmlns:wsse=\"#{wsse_namespace}\">")

          # split up to prevent problems with unordered Hash attributes in 1.8 [dh, 2012-12-13]
          expect(request).to include("<wsse:UsernameToken")
          expect(request).to include("wsu:Id=\"UsernameToken-1\"")
          expect(request).to include("xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\"")

          # the username node
          expect(request).to include("<wsse:Username>#{username}</wsse:Username>")

          # the nonce node
          expect(request).to match(/<wsse:Nonce.*>.+\n<\/wsse:Nonce>/)

          # the created node with a timestamp
          expect(request).to match(/<wsu:Created>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*<\/wsu:Created>/)

          # the password node contains the encrypted value
          password_digest = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"
          expect(request).to match(/<wsse:Password Type=\"#{password_digest}\">.+<\/wsse:Password>/)
          expect(request).to_not include(password)
        end
      end


      context "global" do
        let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_auth => [username, password, :digest]) }
        let(:response) { client.call(:authenticate) }
        include_examples "WSSE digest auth"
      end

      context "local" do
        let(:client) { new_client(:endpoint => @server.url(:repeat)) }
        let(:response) do
          client.call(:authenticate) do |locals|
            locals.wsse_auth(username, password, :digest)
          end
        end
        include_examples "WSSE digest auth"
      end
    end
  end

  context ":wsse_timestamp" do
    let(:request) { response.http.body }

    shared_examples "WSSE timestamp" do
      it "adds WSSE timestamp auth information to the request" do
        # the header and wsse security node
        wsse_namespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
        expect(request).to include("<env:Header><wsse:Security xmlns:wsse=\"#{wsse_namespace}\">")

        # split up to prevent problems with unordered Hash attributes in 1.8 [dh, 2012-12-13]
        expect(request).to include("<wsu:Timestamp")
        expect(request).to include("wsu:Id=\"Timestamp-1\"")
        expect(request).to include("xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\"")

        # the created node with a timestamp
        expect(request).to match(/<wsu:Created>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*<\/wsu:Created>/)

        # the expires node with a timestamp
        expect(request).to match(/<wsu:Expires>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*<\/wsu:Expires>/)
      end
    end

    context "global" do
        let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_timestamp => true) }
        let(:response) { client.call(:authenticate) }
        include_examples "WSSE timestamp"
    end

    context "local" do
      let(:client) { new_client(:endpoint => @server.url(:repeat)) }
      let(:response) do
        client.call(:authenticate) do |locals|
          locals.wsse_timestamp(true)
        end
      end
      include_examples "WSSE timestamp"
    end
  end

  context "global :strip_namespaces" do
    it "can be changed to not strip any namespaces" do
      client = new_client(
        :endpoint => @server.url(:repeat),
        :convert_response_tags_to => lambda { |tag| tag.snakecase },
        :strip_namespaces => false
      )

      response = client.call(:authenticate, :xml => Fixture.response(:authentication))

      expect(response.hash["soap:envelope"]["soap:body"]).to include("ns2:authenticate_response")
    end
  end

  context "global :convert_request_keys_to" do
    it "changes how Hash message key Symbols are translated to XML tags for the request" do
      client = new_client_without_wsdl do |globals|
        globals.endpoint @server.url(:repeat)
        globals.namespace "http://v1.example.com"
        globals.convert_request_keys_to :camelcase  # or one of [:lower_camelcase, :upcase, :none]
      end

      response = client.call(:find_user) do |locals|
        locals.message(:user_name => "luke", "pass_word" => "secret")
      end

      request = response.http.body

      # split into multiple assertions thanks to 1.8
      expect(request).to include("<wsdl:FindUser>")
      expect(request).to include("<UserName>luke</UserName>")
      expect(request).to include("<pass_word>secret</pass_word>")
    end
  end

  context "global :convert_response_tags_to" do
    it "changes how XML tags from the SOAP response are translated into Hash keys" do
      client = new_client(:endpoint => @server.url(:repeat), :convert_response_tags_to => lambda { |tag| tag.snakecase.upcase })
      response = client.call(:authenticate, :xml => Fixture.response(:authentication))

      expect(response.hash["ENVELOPE"]["BODY"]).to include("AUTHENTICATE_RESPONSE")
    end

    it "accepts a block in the block-based interface" do
      client = Savon.client do |globals|
        globals.log                      false
        globals.wsdl                     Fixture.wsdl(:authentication)
        globals.endpoint                 @server.url(:repeat)
        globals.convert_response_tags_to { |tag| tag.snakecase.upcase }
      end

      response = client.call(:authenticate) do |locals|
        locals.xml Fixture.response(:authentication)
      end

      expect(response.hash["ENVELOPE"]["BODY"]).to include("AUTHENTICATE_RESPONSE")
    end
  end

  context "global :convert_attributes_to" do
    it "changes how XML tag attributes from the SOAP response are translated into Hash keys" do
      client = new_client(:endpoint => @server.url(:repeat), :convert_attributes_to => lambda {|k,v| [k,v]})
      response = client.call(:authenticate, :xml => Fixture.response(:f5))
      expect(response.body[:get_agent_listen_address_response][:return][:item].first[:ipport][:address]).to eq({:"@s:type"=>"y:string"})
    end

    it "strips the attributes if an appropriate lambda is set" do
      client = new_client(:endpoint => @server.url(:repeat), :convert_attributes_to => lambda {|k,v| []})
      response = client.call(:authenticate, :xml => Fixture.response(:f5))
      expect(response.body[:get_agent_listen_address_response][:return][:item].first[:ipport][:address]).to eq(nil)
    end

    it "accepts a block in the block-based interface" do
      client = Savon.client do |globals|
        globals.log                      false
        globals.wsdl                     Fixture.wsdl(:authentication)
        globals.endpoint                 @server.url(:repeat)
        globals.convert_attributes_to    {|k,v| [k,v]}
      end

      response = client.call(:authenticate) do |locals|
        locals.xml Fixture.response(:f5)
      end

      expect(response.body[:get_agent_listen_address_response][:return][:item].first[:ipport][:address]).to eq({:"@s:type"=>"y:string"})
    end
  end

  context 'global: :adapter' do
    it 'passes option to Wasabi initializer for WSDL fetching' do
      ## I want to use there something similar to the next mock expectation, but I can't
      ## as due to how Savon sets up Wasabi::Document and Wasabi::Document initialize itself
      ## adapter= method is called first time with nil and second time with adapter. [Envek, 2014-05-03]
      # Wasabi::Document.any_instance.expects(:adapter=).with(:fake_adapter_for_test)
      client = Savon.client(
          :log => false,
          :wsdl => @server.url(:authentication),
          :adapter => :fake_adapter_for_test,
      )
      operations = client.operations
      expect(operations).to eq([:authenticate])
      expect(FakeAdapterForTest.class_variable_get(:@@requests).size).to eq(1)
      expect(FakeAdapterForTest.class_variable_get(:@@requests).first.url).to eq(URI.parse(@server.url(:authentication)))
      expect(FakeAdapterForTest.class_variable_get(:@@methods)).to eq([:get])
    end

    it 'instructs HTTPI to use provided adapter for performing SOAP requests' do
      client = new_client_without_wsdl(
          :endpoint => @server.url(:repeat),
          :namespace => "http://v1.example.com",
          :adapter => :adapter_for_test,
      )
      response = client.call(:authenticate)
      expect(response.http.body).to include('xmlns:wsdl="http://v1.example.com"')
      expect(response.http.body).to include('<wsdl:authenticate>')
      expect(AdapterForTest.class_variable_get(:@@requests).size).to eq(1)
      expect(AdapterForTest.class_variable_get(:@@requests).first.url).to eq(URI.parse(@server.url(:repeat)))
      expect(AdapterForTest.class_variable_get(:@@methods)).to eq([:post])
    end
  end

  context "global and request :soap_header" do
    it "merges the headers if both were provided as Hashes" do
      global_soap_header = {
        :global_header => { :auth_token => "secret" },
        :merged => { :global => true }
      }

      request_soap_header = {
        :request_header => { :auth_token => "secret" },
        :merged => { :request => true }
      }

      client = new_client(:endpoint => @server.url(:repeat), :soap_header => global_soap_header)

      response = client.call(:authenticate, :soap_header => request_soap_header)
      request_body = response.http.body

      expect(request_body).to include("<globalHeader><authToken>secret</authToken></globalHeader>")
      expect(request_body).to include("<requestHeader><authToken>secret</authToken></requestHeader>")
      expect(request_body).to include("<merged><request>true</request></merged>")
    end

    it "prefers the request over the global option if at least one of them is not a Hash" do
      global_soap_header  = "<global>header</global>"
      request_soap_header = "<request>header</request>"

      client = new_client(:endpoint => @server.url(:repeat), :soap_header => global_soap_header)

      response = client.call(:authenticate, :soap_header => request_soap_header)
      request_body = response.http.body

      expect(request_body).to include("<env:Header><request>header</request></env:Header>")
    end
  end

  context "request :soap_header" do
    it "accepts a Hash of SOAP header information" do
      client = new_client(:endpoint => @server.url(:repeat))

      response = client.call(:authenticate, :soap_header => { :auth_token => "secret" })
      expect(response.http.body).to include("<env:Header><authToken>secret</authToken></env:Header>")
    end

    it "accepts anything other than a String and calls #to_s on it" do
      to_s_header = Class.new {
        def to_s
          "to_s_header"
        end
      }.new

      client = new_client(:endpoint => @server.url(:repeat))

      response = client.call(:authenticate, :soap_header => to_s_header)
      expect(response.http.body).to include("<env:Header>to_s_header</env:Header>")
    end
  end

  context "request: message_tag" do
    it "when set, changes the SOAP message tag" do
      response = new_client(:endpoint => @server.url(:repeat)).call(:authenticate, :message_tag => :doAuthenticate)
      expect(response.http.body).to include("<tns:doAuthenticate></tns:doAuthenticate>")
    end

    it "without it, Savon tries to get the message tag from the WSDL document" do
      response = new_client(:endpoint => @server.url(:repeat)).call(:authenticate)
      expect(response.http.body).to include("<tns:authenticate></tns:authenticate>")
    end

    it "without the option and a WSDL, Savon defaults to Gyoku to create the name" do
      client = Savon.client(:endpoint => @server.url(:repeat), :namespace => "http://v1.example.com", :log => false)

      response = client.call(:init_authentication)
      expect(response.http.body).to include("<wsdl:initAuthentication></wsdl:initAuthentication>")
    end
  end

  context "request: attributes" do
    it "when set, adds the attributes to the message tag" do
      client   = new_client(:endpoint => @server.url(:repeat))
      response = client.call(:authenticate, :attributes => { "Token" => "secret"})

      expect(response.http.body).to include('<tns:authenticate Token="secret">')
    end
  end

  context "request: soap_action" do
    it "without it, Savon tries to get the SOAPAction from the WSDL document and falls back to Gyoku" do
      client = new_client(:endpoint => @server.url(:inspect_request))

      response = client.call(:authenticate)
      soap_action = inspect_request(response).soap_action
      expect(soap_action).to eq('"authenticate"')
    end

    it "when set, changes the SOAPAction HTTP header" do
      client = new_client(:endpoint => @server.url(:inspect_request))

      response = client.call(:authenticate, :soap_action => "doAuthenticate")
      soap_action = inspect_request(response).soap_action
      expect(soap_action).to eq('"doAuthenticate"')
    end
  end

  context "request :message" do
    it "accepts a Hash which is passed to Gyoku to be converted to XML" do
      response = new_client(:endpoint => @server.url(:repeat)).call(:authenticate, :message => { :user => "luke", :password => "secret" })

      request = response.http.body
      expect(request).to include("<user>luke</user>")
      expect(request).to include("<password>secret</password>")
    end

    it "also accepts a String of raw XML" do
      response = new_client(:endpoint => @server.url(:repeat)).call(:authenticate, :message => "<user>lea</user><password>top-secret</password>")
      expect(response.http.body).to include("<tns:authenticate><user>lea</user><password>top-secret</password></tns:authenticate>")
    end
  end

  context "request :xml" do
    it "accepts a String of raw XML" do
      response = new_client(:endpoint => @server.url(:repeat)).call(:authenticate, :xml => "<soap>request</soap>")
      expect(response.http.body).to eq("<soap>request</soap>")
    end
  end

  context "request :cookies" do
    it "accepts an Array of HTTPI::Cookie objects for the next request" do
      cookies  = [
        HTTPI::Cookie.new("some-cookie=choc-chip"),
        HTTPI::Cookie.new("another-cookie=ny-cheesecake")
      ]

      client   = new_client(:endpoint => @server.url(:inspect_request))
      response = client.call(:authenticate, :cookies => cookies)

      cookie = inspect_request(response).cookie
      expect(cookie.split(";")).to include(
        "some-cookie=choc-chip",
        "another-cookie=ny-cheesecake"
      )
    end
  end

  context "request :advanced_typecasting" do
    it "can be changed to false to disable Nori's advanced typecasting" do
      client = new_client(:endpoint => @server.url(:repeat))
      response = client.call(:authenticate, :xml => Fixture.response(:authentication), :advanced_typecasting => false)

      expect(response.body[:authenticate_response][:return][:success]).to eq("true")
    end
  end

  context "request :response_parser" do
    it "instructs Nori to change the response parser" do
      nori = Nori.new(:strip_namespaces => true, :convert_tags_to => lambda { |tag| tag.snakecase.to_sym })
      Nori.expects(:new).with { |options| options[:parser] == :nokogiri }.returns(nori)

      client = new_client(:endpoint => @server.url(:repeat))
      response = client.call(:authenticate, :xml => Fixture.response(:authentication), :response_parser => :nokogiri)

      expect(response.body).to_not be_empty
    end
  end

  def new_client(globals = {}, &block)
    globals = { :wsdl => Fixture.wsdl(:authentication), :log => false }.merge(globals)
    Savon.client(globals, &block)
  end

  def new_client_without_wsdl(globals = {}, &block)
    globals = { :log => false }.merge(globals)
    Savon.client(globals, &block)
  end

  def inspect_request(response)
    hash = JSON.parse(response.http.body)
    OpenStruct.new(hash)
  end

end
