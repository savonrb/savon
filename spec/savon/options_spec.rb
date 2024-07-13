# frozen_string_literal: true
require "spec_helper"
require "integration/support/server"
require "json"
require "ostruct"
require "logger"

RSpec.describe "Options" do

  shared_examples(:deprecation) do |option|
    it "Raises a deprecation error" do
      expect { new_client(:endpoint => @server.url, option => :none) }.to(
        raise_error(Savon::DeprecatedOptionError) {|e|
          expect(e.option).to eql(option.to_s)
        })
    end
  end

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

  context 'global :follow_redirects' do
    # From the documentation, this might have compatability issues with ntlm due to its reliance on net-http-persistent
    # TODO integration test this somehow....
    it 'sets whether or not request should follow redirects' do
      client = new_client(:endpoint => @server.url, :follow_redirects => true)

      Faraday::Connection.any_instance.expects(:response).with(:follow_redirects)

      client.call(:authenticate)
    end

    it 'defaults to false' do
      client = new_client(:endpoint => @server.url)

      Faraday::Connection.any_instance.expects(:response).with(:follow_redirects).never

      client.call(:authenticate)
    end
  end

  context "global :proxy" do
    it "sets the proxy server to use" do
      proxy_url = "http://example.com"
      client = new_client(:endpoint => @server.url, :proxy => proxy_url)

      # TODO: find a way to integration test this [dh, 2012-12-08]
      Faraday::Connection.any_instance.expects(:proxy=).with(proxy_url)

      response = client.call(:authenticate)
    end
  end

  context "global :host" do
    let(:host) { "https://example.com:8080" }
    let(:path) { "#{host}/webserviceexternal/contracts.asmx"}
    it "overrides the WSDL endpoint host" do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post(path) do
        [200, {'Content-Type': 'application/xml'}, '<xml/>']
      end

      client = new_client(:wsdl => Fixture.wsdl(:no_message_tag), host: host, adapter: [:test, stubs] )

      client.call(:update_orders)
      expect{stubs.verify_stubbed_calls}.not_to raise_error
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
    let(:open_timeout) { 0.1 }
    it "makes the client timeout after n seconds" do
      non_routable_ip = "http://192.0.2.0"
      client = new_client(:endpoint => non_routable_ip, :open_timeout => open_timeout)
      start_time = Time.now
      expect { client.call(:authenticate) }.to raise_error { |error|
        host_unreachable = error.kind_of? Errno::EHOSTUNREACH
        net_unreachable = error.kind_of? Errno::ENETUNREACH
        socket_err = error.kind_of? SocketError
        if host_unreachable || net_unreachable || socket_err
          warn "Warning: looks like your network may be down?!\n" +
               "-> skipping spec at #{__FILE__}:#{__LINE__}"
        else
          expect(Time.now - start_time).to be_within(0.5).of(open_timeout)
          expect(error).to be_an(Faraday::ConnectionFailed)
        end
      }
    end
  end

  context "global :read_timeout" do
    it "makes the client timeout after n seconds" do
      client = new_client(:endpoint => @server.url(:timeout), :open_timeout => 0.1, :read_timeout => 0.1)

      expect { client.call(:authenticate) }.
        to raise_error(Faraday::TimeoutError)
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

    it "qualifies elements embedded in complex types" do
      client = new_client(:endpoint => @server.url(:repeat),
                          :wsdl => Fixture.wsdl(:elements_in_types))
      msg = {":TopLevelTransaction"=>{":Qualified"=>"A Value"}}

      response = client.call(:top_level_transaction, :message => msg)

      expect(response.http.body.scan(/<tns:Qualified>/).count).to eq(1)
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

    it "silences Faraday as well" do
      Faraday::Connection.any_instance.expects(:response).with(:logger, nil, {:headers => true, :level => 0}).never

      new_client(:log => false)
    end

    it "instructs Savon to log SOAP requests and responses" do
      stdout = mock_stdout do
        client = new_client(:endpoint => @server.url, :log => true)
        client.call(:authenticate)
      end

      expect(stdout.string).to include("INFO -- : SOAP request")
    end

    it "turns Faraday logging back on as well" do
      Faraday::Connection.any_instance.expects(:response).with(:logger, nil, {:headers => true, :level => 0}).at_least_once
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

    it "sets the logger of faraday connection as well" do
      Faraday::Connection.any_instance.expects(:response).with(:logger, nil, {:headers => true, :level => 0}).at_least_once
      mock_stdout {
        custom_logger = Logger.new($stdout)

        client = new_client(:endpoint => @server.url, :logger => custom_logger, :log => true)
        client.call(:authenticate)
      }
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

  context "global :log_headers" do
    it "instructs Savon to log SOAP requests and responses headers" do
      stdout = mock_stdout {
        client = new_client(:endpoint => @server.url, :log => true)
        client.call(:authenticate)
      }
      soap_header = stdout.string.downcase.include? "content-type"
      expect(soap_header).to be true
    end

    it "stops Savon from logging SOAP requests and responses headers" do
      stdout = mock_stdout {
        client = new_client(:endpoint => @server.url, :log => true, :log_headers => false)
        client.call(:authenticate)
      }
      soap_header = stdout.string.include? "Content-Type"
      expect(soap_header).to be false
    end
  end

  context "global :ssl_version" do
    it "sets the SSL version to use" do
      Faraday::SSLOptions.any_instance.expects(:version=).with(:TLSv1).twice

      client = new_client(:endpoint => @server.url, :ssl_version => :TLSv1)
      client.call(:authenticate)
    end
  end

  context "global :ssl_min_version" do
    it "sets the SSL min_version to use" do
      Faraday::SSLOptions.any_instance.expects(:min_version=).with(:TLS1_2).twice

      client = new_client(:endpoint => @server.url, :ssl_min_version => :TLS1_2)
      client.call(:authenticate)
    end
  end

  context "global :ssl_max_version" do
    it "sets the SSL max_version to use" do
      Faraday::SSLOptions.any_instance.expects(:max_version=).with(:TLS1_2).twice

      client = new_client(:endpoint => @server.url, :ssl_max_version => :TLS1_2)
      client.call(:authenticate)
    end
  end

  context "global :ssl_verify_mode" do
    it "sets the verify mode to use" do
      Faraday::SSLOptions.any_instance.expects(:verify_mode=).with(:peer).twice

      client = new_client(:endpoint => @server.url, :ssl_verify_mode => :peer)
      client.call(:authenticate)
    end
  end

  context "global :ssl_ciphers" do
    it_behaves_like(:deprecation, :ssl_ciphers)
  end

  context "global :ssl_cert_key_file" do
    it_behaves_like(:deprecation, :ssl_cert_key_file)
  end

  context "global :ssl_cert_key" do
    it "sets the cert key to use" do
      cert_key = File.open(File.expand_path("../../fixtures/ssl/client_key.pem", __FILE__)).read
      Faraday::SSLOptions.any_instance.expects(:client_key=).with(cert_key).twice

      client = new_client(:endpoint => @server.url, :ssl_cert_key => cert_key)
      client.call(:authenticate)
    end
  end


  context "global :ssl_cert_key_password" do
    it_behaves_like(:deprecation, :ssl_cert_key_password)
  end

  context "global :ssl_cert_file" do
    it_behaves_like(:deprecation, :ssl_cert_file)
  end

  context "global :ssl_cert" do
    it "sets the cert to use" do
      cert = File.open(File.expand_path("../../fixtures/ssl/client_cert.pem", __FILE__)).read
      Faraday::SSLOptions.any_instance.expects(:client_cert=).with(cert).twice

      client = new_client(:endpoint => @server.url, :ssl_cert => cert)
      client.call(:authenticate)
    end
  end

  context "global :ssl_ca_cert_file" do
    it "sets the ca cert file to use" do
      ca_cert = File.expand_path("../../fixtures/ssl/client_cert.pem", __FILE__)
      Faraday::SSLOptions.any_instance.expects(:ca_file=).with(ca_cert).twice

      client = new_client(:endpoint => @server.url, :ssl_ca_cert_file => ca_cert)
      client.call(:authenticate)
    end
  end

  context "global :ssl_ca_cert_path" do
    it "sets the ca cert path to use" do
      ca_cert_path = "../../fixtures/ssl"
      Faraday::SSLOptions.any_instance.expects(:ca_path=).with(ca_cert_path).twice

      client = new_client(:endpoint => @server.url, :ssl_ca_cert_path => ca_cert_path)
      client.call(:authenticate)
    end
  end

  context "global :ssl_ca_cert_store" do
    it "sets the cert store to use" do
      cert_store = OpenSSL::X509::Store.new
      Faraday::SSLOptions.any_instance.expects(:cert_store=).with(cert_store).twice

      client = new_client(:endpoint => @server.url, :ssl_cert_store => cert_store)
      client.call(:authenticate)
    end
  end

  context "global :ssl_ca_cert" do
    it_behaves_like(:deprecation, :ssl_ca_cert)
  end


  context "global :basic_auth" do
    it "sets the basic auth credentials" do
      client = new_client(:endpoint => @server.url(:basic_auth), :basic_auth => ["admin", "secret"])
      response = client.call(:authenticate)

      expect(response.http.body).to eq("basic-auth")
    end
  end

  context "global :ntlm" do
    it "sets the ntlm credentials to use" do
      credentials = ["admin", "secret"]
      client = new_client(:endpoint => @server.url, :ntlm => credentials)

      # TODO: find a way to integration test this. including an entire ntlm
      # server implementation seems a bit over the top though.
      Savon::Operation.any_instance.expects(:handle_ntlm)

      response = client.call(:authenticate)
    end
  end

  context "global :filters" do
    it "filters a list of XML tags from logged SOAP messages" do
      captured = mock_stdout do
        client = new_client(:endpoint => @server.url(:repeat), :log => true)
        client.globals[:filters] << :password

        message = { :username => "luke", :password => "secret" }
        client.call(:authenticate, :message => message)
      end

      captured.rewind
      messages = captured.readlines.join("\n")

      expect(messages).to include("<password>***FILTERED***</password>")
    end
  end

  context "global :pretty_print_xml" do
    it "is a nice but expensive way to debug XML messages" do
      captured = mock_stdout do
        client = new_client(
          :endpoint => @server.url(:repeat),
          :pretty_print_xml => true,
          :log => true)
        client.globals[:logger].formatter = proc { |*, msg| "#{msg}\n" }

        client.call(:authenticate)
      end

      captured.rewind
      messages = captured.readlines.join("\n")

      expect(messages).to match(/\n<env:Envelope/)
      expect(messages).to match(/\n  <env:Body/)
      expect(messages).to match(/\n    <tns:authenticate/)
    end
  end

  context ":wsse_auth" do
    let(:username) { "luke" }
    let(:password) { "secret" }
    let(:request) { response.http.body }

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
        expect(request).to match(/<wsse:Nonce.*>.+\n?<\/wsse:Nonce>/)

        # the created node with a timestamp
        expect(request).to match(/<wsu:Created>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*<\/wsu:Created>/)

        # the password node contains the encrypted value
        password_digest = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"
        expect(request).to match(/<wsse:Password Type=\"#{password_digest}\">.+<\/wsse:Password>/)
        expect(request).to_not include(password)
      end
    end

    shared_examples "no WSSE auth" do
      it "does not add WSSE auth to the request" do
        expect(request).not_to include("<wsse:UsernameToken")
      end
    end

    describe "global" do
      context "enabled" do
        context "without digest" do
          let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_auth => [username, password]) }
          let(:response) { client.call(:authenticate) }
          include_examples "WSSE basic auth"
        end

        context "with digest" do
          let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_auth => [username, password, :digest]) }
          let(:response) { client.call(:authenticate) }
          include_examples "WSSE digest auth"
        end

        context "local override" do
          let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_auth => ["luke", "secret"]) }

          context "enabled" do
            let(:username) { "lea" }
            let(:password) { "top-secret" }

            context "without digest" do
              let(:response) { client.call(:authenticate) {|locals| locals.wsse_auth(username, password)} }
              include_examples "WSSE basic auth"
            end

            context "with digest" do
              let(:response) { client.call(:authenticate) {|locals| locals.wsse_auth(username, password, :digest)} }
              include_examples "WSSE digest auth"
            end
          end

          context "disabled" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_auth(false)} }
            include_examples "no WSSE auth"
          end

          context "set to nil" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_auth(nil)} }
            include_examples "WSSE basic auth"
          end
        end

        context "global" do
          let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_auth => [username, password, :digest]) }
          let(:response) { client.call(:authenticate) }
          include_examples "WSSE digest auth"
        end
      end

      context "not enabled" do
        let(:client) { new_client(:endpoint => @server.url(:repeat)) }

        describe "local" do
          context "enabled" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_auth(username, password, :digest)} }
            include_examples "WSSE digest auth"
          end

          context "disabled" do
            let(:response) { client.call(:authenticate) { |locals| locals.wsse_auth(false)} }
            include_examples "no WSSE auth"
          end

          context "set to nil" do
            let(:response) { client.call(:authenticate) { |locals| locals.wsse_auth(nil)} }
            include_examples "no WSSE auth"
          end
        end
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

    shared_examples "no WSSE timestamp" do
      it "does not add WSSE timestamp to the request" do
        expect(request).not_to include("<wsu:Timestamp")
      end
    end

    describe "global" do
      context "enabled" do
        context "through block without arguments" do
          let(:client) do
            new_client(:endpoint => @server.url(:repeat)) do |globals|
              globals.wsse_timestamp
            end
          end
          let(:response) { client.call(:authenticate) }
          include_examples "WSSE timestamp"
        end

        context "through initializer options" do
          let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_timestamp => true) }
          let(:response) { client.call(:authenticate) }
          include_examples "WSSE timestamp"
        end

        context "with local override" do
          let(:client) { new_client(:endpoint => @server.url(:repeat), :wsse_timestamp => true) }
          context "enabled" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_timestamp} }
            include_examples "WSSE timestamp"
          end
          context "disabled" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_timestamp(false) } }
            include_examples "no WSSE timestamp"
          end
          context "set to nil" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_timestamp(nil) } }
            include_examples "WSSE timestamp"
          end
        end
      end

      context "not enabled" do
        let(:client) { new_client(:endpoint => @server.url(:repeat)) }
        describe "local" do
          context "enabled" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_timestamp} }
            include_examples "WSSE timestamp"
          end
          context "disabled" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_timestamp(false) } }
            include_examples "no WSSE timestamp"
          end
          context "set to nil" do
            let(:response) { client.call(:authenticate) {|locals| locals.wsse_timestamp(nil) } }
            include_examples "no WSSE timestamp"
          end
        end
      end
    end
  end

  context "global :strip_namespaces" do
    it "can be changed to not strip any namespaces" do
      client = new_client(
        :endpoint => @server.url(:repeat),
        :convert_response_tags_to => lambda { |tag| Savon::StringUtils.snakecase(tag) },
        :strip_namespaces => false
      )

      response = client.call(:authenticate, :xml => Fixture.response(:authentication))

      expect(response.full_hash["soap:envelope"]["soap:body"]).to include("ns2:authenticate_response")
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
      client = new_client(:endpoint => @server.url(:repeat), :convert_response_tags_to => lambda { |tag| Savon::StringUtils.snakecase(tag).upcase })
      response = client.call(:authenticate, :xml => Fixture.response(:authentication))

      expect(response.full_hash["ENVELOPE"]["BODY"]).to include("AUTHENTICATE_RESPONSE")
    end

    it "accepts a block in the block-based interface" do
      client = Savon.client do |globals|
        globals.log                      false
        globals.wsdl                     Fixture.wsdl(:authentication)
        globals.endpoint                 @server.url(:repeat)
        globals.convert_response_tags_to { |tag| Savon::StringUtils.snakecase(tag).upcase }
      end

      response = client.call(:authenticate) do |locals|
        locals.xml Fixture.response(:authentication)
      end

      expect(response.full_hash["ENVELOPE"]["BODY"]).to include("AUTHENTICATE_RESPONSE")
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
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get(@server.url('authentication')) do
        [200, {'Content-Type': 'application/xml'}, Fixture.wsdl('authentication')]
      end
      Wasabi::Document.any_instance.expects(:adapter=).with(nil)
      Wasabi::Document.any_instance.expects(:adapter=).with([:test, stubs])
      client = Savon.client(
          :log => false,
          :wsdl => @server.url(:authentication),
          :adapter => [:test, stubs],
      )
      client.operations
      expect{stubs.verify_stubbed_calls}.not_to raise_error
    end

    it 'instructs Faraday to use a provided adapter for performing SOAP requests' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post(@server.url('repeat')) do
        [200, {'Content-Type': 'application/xml'}, Fixture.response('authentication')]
      end
      client = new_client_without_wsdl(
          :endpoint => @server.url(:repeat),
          :namespace => "http://v1_0.ws.user.example.com",
          :adapter => [:test, stubs],
      )
      response = client.call(:authenticate)
      expect(response.http.body).to include('<ns2:authenticateResponse xmlns:ns2="http://v1_0.ws.user.example.com">')
      expect(response.http.body).to include('<authenticationValue>')
      expect{stubs.verify_stubbed_calls}.not_to raise_error
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
    it "accepts a hash for the next request" do
      cookies = {
        'some-cookie': 'choc-chip',
        'another-cookie': 'ny-cheesecake'
      }

      client   = new_client(:endpoint => @server.url(:inspect_request))
      response = client.call(:authenticate, :cookies => cookies)

      cookie = inspect_request(response).cookie
      expect(cookie.split("; ")).to include(
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
      nori = Nori.new(:strip_namespaces => true, :convert_tags_to => lambda { |tag| Savon::StringUtils.snakecase(tag).to_sym })
      Nori.expects(:new).with { |options| options[:parser] == :nokogiri }.returns(nori)

      client = new_client(:endpoint => @server.url(:repeat))
      response = client.call(:authenticate, :xml => Fixture.response(:authentication), :response_parser => :nokogiri)

      expect(response.body).to_not be_empty
    end
  end

  context "request :headers" do
    it "sets headers" do
      client = new_client(:endpoint => @server.url(:inspect_request))

      response = client.call(:authenticate, :headers => { "X-Token" => "secret" })
      x_token  = inspect_request(response).x_token

      expect(x_token).to eq("secret")
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
