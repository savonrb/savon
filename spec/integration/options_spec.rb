require "spec_helper"
require "integration/support/server"

describe "NewClient Options" do

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

  context "soap_header" do
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
      expect(response.http.body).to include("<tns:user>luke</tns:user><tns:password>secret</tns:password>")

      # unqualified
      client = new_client(:endpoint => @server.url(:repeat), :element_form_default => :unqualified)

      response = client.call(:authenticate, :message => { :user => "lea", :password => "top-secret" })
      expect(response.http.body).to include("<user>lea</user><password>top-secret</password>")
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

      client = new_client(:logger => duck_logger.new)
      client.call(:authenticate)

      expect(duck_logger.logs).to include("SOAP request: http://example.com/validation/1.0/AuthenticationService")
    end
  end

  context "global :basic_auth" do
    it "sets the basic auth credentials" do
      client = new_client(:endpoint => @server.url(:basic_auth), :basic_auth => ["admin", "secret"])
      response = client.call(:authenticate)

      expect(response.http.body).to eq("basic-auth")
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

      client = new_client(:logger => duck_logger.new, :pretty_print_xml => true)
      client.call(:authenticate)

      xml = unindent <<-xml
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <env:Envelope xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:tns=\"http://v1_0.ws.auth.order.example.com/\" xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\">
          <env:Body>
            <tns:authenticate/>
          </env:Body>
        </env:Envelope>
       xml

      expect(duck_logger.logs[2]).to eq(xml)
    end

    def unindent(string)
      string.gsub(/^#{string[/\A\s*/]}/, '')
    end

  end

  context "request: message_tag" do
    it "without it, Savon tries to get the message tag from the WSDL document and falls back to Gyoku" do
      response = new_client(:endpoint => @server.url(:repeat)).call(:authenticate)
      expect(response.http.body).to include("<tns:authenticate></tns:authenticate>")
    end

    it "when set, changes the SOAP message tag" do
      response = new_client(:endpoint => @server.url(:repeat)).call(:authenticate, :message_tag => :doAuthenticate)
      expect(response.http.body).to include("<tns:doAuthenticate></tns:doAuthenticate>")
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

  def new_client(globals = {})
    globals = { :logger => Savon::NullLogger.new, :wsdl => Fixture.wsdl(:authentication) }.merge(globals)
    Savon.new_client(globals)
  end

  def new_client_without_wsdl(globals = {})
    globals = { :logger => Savon::NullLogger.new }.merge(globals)
    Savon.new_client(globals)
  end

end
