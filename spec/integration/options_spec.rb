require "spec_helper"
require "integration/support/server"

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
      client = new_client(:endpoint => @server.url(:repeat_header), :headers => { "Repeat-Header" => "savon" })

      response = client.call(:authenticate)
      expect(response.http.body).to eq("savon")
    end
  end

  context "global :open_timeout" do
    it "makes the client timeout after n seconds" do
      non_routable_ip = "http://10.255.255.1"
      client = new_client(:endpoint => non_routable_ip, :open_timeout => 1)

      # TODO: make HTTPI tag timeout errors, then depend on HTTPI::TimeoutError instead of a specific client error [dh, 2012-12-08]
      expect { client.call(:authenticate) }.to raise_error(HTTPClient::ConnectTimeoutError)
    end
  end

  context "global :read_timeout" do
    it "makes the client timeout after n seconds" do
      client = new_client(:endpoint => @server.url(:timeout), :open_timeout => 1, :read_timeout => 1)

      expect { client.call(:authenticate) }.to raise_error(HTTPClient::ReceiveTimeoutError)
    end
  end

  context "global :encoding" do
    it "changes the XML instruction" do
      client = new_client(:endpoint => @server.url(:repeat), :encoding => "UTF-16")
      response = client.call(:authenticate)

      expect(response.http.body).to match(/<\?xml version="1\.0" encoding="UTF-16"\?>/)
    end

    it "changes the Content-Type header" do
      client = new_client(:endpoint => @server.url(:inspect_header), :encoding => "UTF-16",
                          :headers => { "Inspect" => "CONTENT_TYPE" })

      response = client.call(:authenticate)
      expect(response.http.body).to eq("text/xml;charset=UTF-16")
    end
  end

  context "global :soap_header" do
    it "accepts a Hash of SOAP header information" do
      client = new_client(:endpoint => @server.url(:repeat), :soap_header => { :auth_token => "secret" })

      response = client.call(:authenticate)
      expect(response.http.body).to include("<env:Header><authToken>secret</authToken></env:Header>")
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

    it "allows overwriting the SOAPAction HTTP header" do
      client = new_client(:endpoint => @server.url(:inspect_header),
                          :headers => { "Inspect" => "HTTP_SOAPACTION" })

      response = client.call(:authenticate)
      expect(response.http.body).to eq('"authenticate"')
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

  context "global :logger" do
    it "defaults to an instance of Savon::Logger" do
      logger = new_client.globals[:logger]
      expect(logger).to be_a(Savon::Logger)
    end

    it "can be replaced by an object that responds to #log" do
      duck_logger = Class.new {

        def self.logs
          @logs ||= []
        end

        def log(message, options = {})
          self.class.logs << message
        end

      }

      client = new_client(:endpoint => @server.url, :logger => duck_logger.new)
      client.call(:authenticate)

      expect(duck_logger.logs).to include("SOAP request: #{@server.url}")
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

  context "global :pretty_print_xml" do
    it "is a nice but expensive way to debug XML messages" do
      duck_logger = Class.new {

        def self.logs
          @logs ||= []
        end

        def log(message, options = {})
          # TODO: probably not the best way to test this, since it repeats the loggers behavior,
          #       but it's currently not possible to easily access the log messages. [dh, 2012-12-09]
          self.class.logs << Savon::LogMessage.new(message, [], options).to_s
        end

      }

      client = new_client(:endpoint => @server.url, :logger => duck_logger.new, :pretty_print_xml => true)
      client.call(:authenticate)

      xml = unindent <<-xml
        <env:Body>
            <tns:authenticate/>
          </env:Body>
      xml

      expect(duck_logger.logs[2]).to include(xml)
    end

    def unindent(string)
      string.gsub(/^#{string[/\A\s*/]}/, '')
    end

  end

  context "global :wsse_auth" do
    it "adds WSSE basic auth information to the request" do
      client = new_client(:endpoint => @server.url(:repeat), :wsse_auth => ["luke", "secret"])
      response = client.call(:authenticate)

      request = response.http.body

      # the header and wsse security node
      wsse_namespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
      expect(request).to include("<env:Header><wsse:Security xmlns:wsse=\"#{wsse_namespace}\">")

      # split up to prevent problems with unordered Hash attributes in 1.8 [dh, 2012-12-13]
      expect(request).to include("<wsse:UsernameToken")
      expect(request).to include("wsu:Id=\"UsernameToken-1\"")
      expect(request).to include("xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\"")

      # the username and password node with type attribute
      expect(request).to include("<wsse:Username>luke</wsse:Username>")
      password_text = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"
      expect(request).to include("<wsse:Password Type=\"#{password_text}\">secret</wsse:Password>")
    end

    it "adds WSSE digest auth information to the request" do
      client = new_client(:endpoint => @server.url(:repeat), :wsse_auth => ["lea", "top-secret", :digest])
      response = client.call(:authenticate)

      request = response.http.body

      # the header and wsse security node
      wsse_namespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
      expect(request).to include("<env:Header><wsse:Security xmlns:wsse=\"#{wsse_namespace}\">")

      # split up to prevent problems with unordered Hash attributes in 1.8 [dh, 2012-12-13]
      expect(request).to include("<wsse:UsernameToken")
      expect(request).to include("wsu:Id=\"UsernameToken-1\"")
      expect(request).to include("xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\"")

      # the username node
      expect(request).to include("<wsse:Username>lea</wsse:Username>")

      # the nonce node
      expect(request).to match(/<wsse:Nonce>.+<\/wsse:Nonce>/)

      # the created node with a timestamp
      expect(request).to match(/<wsu:Created>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*<\/wsu:Created>/)

      # the password node contains the encrypted value
      password_digest = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"
      expect(request).to match(/<wsse:Password Type=\"#{password_digest}\">.+<\/wsse:Password>/)
      expect(request).to_not include("top-secret")
    end
  end

  context "global :wsse_timestamp" do
    it "adds WSSE timestamp auth information to the request" do
      client = new_client(:endpoint => @server.url(:repeat), :wsse_timestamp => true)
      response = client.call(:authenticate)

      request = response.http.body

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

  context "global :strip_namespaces" do
    it "can be changed to not strip any namespaces" do
      client = new_client(:endpoint => @server.url(:repeat), :convert_tags_to => lambda { |tag| tag.snakecase }, :strip_namespaces => false)
      response = client.call(:authenticate, :xml => Fixture.response(:authentication))

      # the header/body convenience methods fails when conventions are not met. [dh, 2012-12-12]
      expect { response.body }.to raise_error(Savon::InvalidResponseError)

      expect(response.hash["soap:envelope"]["soap:body"]).to include("ns2:authenticate_response")
    end
  end

  context "global :convert_tags_to" do
    it "can be changed to convert XML tags to a different format" do
      client = new_client(:endpoint => @server.url(:repeat), :convert_tags_to => lambda { |tag| tag.snakecase.upcase })
      response = client.call(:authenticate, :xml => Fixture.response(:authentication))

      expect(response.hash["ENVELOPE"]["BODY"]).to include("AUTHENTICATE_RESPONSE")
    end

    it "accepts a block in the block-based interface" do
      client = Savon.client do |globals|
        globals.logger          Savon::NullLogger.new
        globals.wsdl            Fixture.wsdl(:authentication)
        globals.endpoint        @server.url(:repeat)
        globals.convert_tags_to { |tag| tag.snakecase.upcase }
      end

      response = client.call(:authenticate) do |locals|
        locals.xml Fixture.response(:authentication)
      end

      expect(response.hash["ENVELOPE"]["BODY"]).to include("AUTHENTICATE_RESPONSE")
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
      client = Savon.client(:endpoint => @server.url(:repeat), :namespace => "http://v1.example.com",
                            :logger => Savon::NullLogger.new)

      response = client.call(:init_authentication)
      expect(response.http.body).to include("<wsdl:initAuthentication></wsdl:initAuthentication>")
    end
  end

  context "request: soap_action" do
    it "without it, Savon tries to get the SOAPAction from the WSDL document and falls back to Gyoku" do
      client = new_client(:endpoint => @server.url(:inspect_header),
                          :headers => { "Inspect" => "HTTP_SOAPACTION" })

      response = client.call(:authenticate)
      expect(response.http.body).to eq('"authenticate"')
    end

    it "when set, changes the SOAPAction HTTP header" do
      client = new_client(:endpoint => @server.url(:inspect_header),
                          :headers => { "Inspect" => "HTTP_SOAPACTION" })

      response = client.call(:authenticate, :soap_action => "doAuthenticate")
      expect(response.http.body).to eq('"doAuthenticate"')
    end
  end

  context "request :message" do
    it "accepts a Hash which is passed to Gyoku to be converted to XML" do
      response = new_client(:endpoint => @server.url(:repeat)).call(:authenticate, :message => { :user => "luke", :password => "secret" })
      expect(response.http.body).to include("<tns:authenticate><user>luke</user><password>secret</password></tns:authenticate>")
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

  def new_client(globals = {})
    globals = { :logger => Savon::NullLogger.new, :wsdl => Fixture.wsdl(:authentication) }.merge(globals)
    Savon.client(globals)
  end

  def new_client_without_wsdl(globals = {})
    globals = { :logger => Savon::NullLogger.new }.merge(globals)
    Savon.client(globals)
  end

end
