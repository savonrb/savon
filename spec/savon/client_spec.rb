require "spec_helper"

describe Savon::Client do
  let(:client) { Savon::Client.new Endpoint.wsdl }

  describe ".new" do
    context "called with a String" do
      it "sets the WSDL document" do
        wsdl = "http://example.com/UserService?wsdl"
        client = Savon::Client.new wsdl
        client.wsdl.instance_variable_get("@document").should == wsdl
      end
    end

    context "called with a block expecting one argument" do
      it "yields the client instance" do
        Savon::Client.new { |client| client.should be_a(Savon::Client) }
      end
    end

    context "called with a block expecting no arguments" do
      it "lets you access the WSDL object" do
        Savon::Client.new { wsdl.should be_a(Savon::WSDL::Document) }
      end

      it "lets you access the HTTP object" do
        Savon::Client.new { http.should be_an(HTTPI::Request) }
      end

      it "lets you access the WSSE object" do
        Savon::Client.new { wsse.should be_a(Savon::WSSE) }
      end
    end
  end

  describe "#wsdl" do
    it "returns the Savon::WSDL::Document" do
      client.wsdl.should be_a(Savon::WSDL::Document)
    end

    it "memoizes the object" do
      client.wsdl.should equal(client.wsdl)
    end
  end

  describe "#http" do
    it "returns the HTTPI::Request" do
      client.http.should be_an(HTTPI::Request)
    end

    it "memoizes the object" do
      client.http.should equal(client.http)
    end
  end

  describe "#wsse" do
    it "returns the Savon::WSSE object" do
      client.wsse.should be_a(Savon::WSSE)
    end

    it "memoizes the object" do
      client.wsse.should equal(client.wsse)
    end
  end

  describe "#request" do
    before do
      HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:authentication)))
      HTTPI.stubs(:post).returns(new_response)
    end

    context "called without any arguments" do
      it "raises an ArgumentError" do
        message = "Expected to receive at least one argument"
        expect { client.request }.to raise_error(ArgumentError, message)
      end
    end

    context "called with a single argument (Symbol)" do
      it "sets the input tag to result in <getUser>" do
        client.request(:get_user) { soap.input.should == [:getUser, {}] }
      end

      it "sets the target namespace with the default identifier" do
        namespace = 'xmlns:wsdl="http://v1_0.ws.auth.order.example.com/"'
        HTTPI::Request.any_instance.expects(:body=).with { |value| value.include? namespace }

        client.request :get_user
      end

      it "does not set the target namespace if soap.namespace was set to nil" do
        namespace = "http://v1_0.ws.auth.order.example.com/"
        HTTPI::Request.any_instance.expects(:body=).with { |value| !value.include?(namespace) }

        client.request(:get_user) { soap.namespace = nil }
      end
    end

    context "called with a single argument (String)" do
      it "sets the input tag to result in <get_user>" do
        client.request("get_user") { soap.input.should == [:get_user, {}] }
      end
    end

    context "called with a Symbol and a Hash" do
      it "sets the input tag to result in <getUser active='true'>" do
        client.request(:get_user, :active => true) { soap.input.should == [:getUser, { :active => true }] }
      end
    end

    context "called with two Symbols" do
      it "sets the input tag to result in <wsdl:getUser>" do
        client.request(:v1, :get_user) { soap.input.should == [:v1, :getUser, {}] }
      end

      it "sets the target namespace with the given identifier" do
        namespace = 'xmlns:v1="http://v1_0.ws.auth.order.example.com/"'
        HTTPI::Request.any_instance.expects(:body=).with { |value| value.include? namespace }

        client.request :v1, :get_user
      end

      it "does not set the target namespace if soap.namespace was set to nil" do
        namespace = "http://v1_0.ws.auth.order.example.com/"
        HTTPI::Request.any_instance.expects(:body=).with { |value| !value.include?(namespace) }

        client.request(:v1, :get_user) { soap.namespace = nil }
      end
    end

    context "called with two Symbols and a Hash" do
      it "sets the input tag to result in <wsdl:getUser active='true'>" do
        client.request(:wsdl, :get_user, :active => true) { soap.input.should == [:wsdl, :getUser, { :active => true }] }
      end
    end

    context "called with a block expecting one argument" do
      it "yields the client instance" do
        client.request(:authenticate) { |client| client.should be_a(Savon::Client) }
      end
    end

    context "called with a block expecting no arguments" do
      it "lets you access the SOAP object" do
        client.request(:authenticate) { soap.should be_a(Savon::SOAP::XML) }
      end

      it "lets you access the HTTP object" do
        client.request(:authenticate) { http.should be_an(HTTPI::Request) }
      end

      it "lets you access the WSSE object" do
        client.request(:authenticate) { wsse.should be_a(Savon::WSSE) }
      end

      it "lets you access the WSDL object" do
        client.request(:authenticate) { wsdl.should be_a(Savon::WSDL::Document) }
      end
    end

    context "called with a block expecting more than one argument" do
      it "raises an ArgumentError" do
        message = "Expected a block with an arity of either 0 or 1"
        expect { client.request(:authenticate) { |one, two| } }.to raise_error(ArgumentError, message)
      end
    end

    it "by default does not set the Cookie header for the next request" do
      client.http.headers.expects(:[]=).with("Cookie", anything).never
      client.http.headers.stubs(:[]=).with("SOAPAction", '"authenticate"')
      client.http.headers.stubs(:[]=).with("Content-Type", "text/xml;charset=UTF-8")

      client.request :authenticate
    end

    context "with a Set-Cookie response header" do
      before do
        HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:authentication)))
        HTTPI.stubs(:post).returns(new_response(:headers => { "Set-Cookie" => "user:mac" }))
      end

      it "sets the Cookie header for the next request" do
        client.http.headers.expects(:[]=).with("Cookie", "user:mac")
        client.http.headers.stubs(:[]=).with("SOAPAction", '"authenticate"')
        client.http.headers.stubs(:[]=).with("Content-Type", "text/xml;charset=UTF-8")

        client.request :authenticate
      end
    end
  end

  context "with a remote WSDL document" do
    let(:client) { Savon::Client.new Endpoint.wsdl }
    before { HTTPI.expects(:get).returns(new_response(:body => Fixture.wsdl(:authentication))) }

    it "returns a list of available SOAP actions" do
      client.wsdl.soap_actions.should == [:authenticate]
    end

    it "adds a SOAPAction header containing the SOAP action name" do
      HTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "executes SOAP requests and returns the response" do
      HTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(Savon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "with a local WSDL document" do
    let(:client) { Savon::Client.new "spec/fixtures/wsdl/authentication.xml" }

    before { HTTPI.expects(:get).never }

    it "returns a list of available SOAP actions" do
      client.wsdl.soap_actions.should == [:authenticate]
    end

    it "adds a SOAPAction header containing the SOAP action name" do
      HTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "gets the value of #element_form_default from the WSDL" do
      HTTPI.stubs(:post).returns(new_response)
      Savon::WSDL::Document.any_instance.expects(:element_form_default).returns(:qualified)

      client.request :authenticate
    end

    it "executes SOAP requests and returns the response" do
      HTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(Savon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "without a WSDL document" do
    let(:client) do
      Savon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before { HTTPI.expects(:get).never }

    it "raises an ArgumentError when trying to access the WSDL" do
      expect { client.wsdl.soap_actions }.to raise_error(ArgumentError)
    end

    it "adds a SOAPAction header containing the SOAP action name" do
      HTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "does not try to get the value of #element_form_default from the WSDL" do
      HTTPI.stubs(:post).returns(new_response)
      Savon::WSDL::Document.any_instance.expects(:element_form_default).never

      client.request :authenticate
    end

    it "executes SOAP requests and returns the response" do
      HTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(Savon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "when encountering a SOAP fault" do
    let(:client) do
      Savon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before do
      response = new_response :code => 500, :body => Fixture.response(:soap_fault)
      HTTPI::expects(:post).returns(response)
    end

    it "raises a Savon::SOAP::Fault" do
      expect { client.request :authenticate }.to raise_error(Savon::SOAP::Fault)
    end
  end

  context "when encountering an HTTP error" do
    let(:client) do
      Savon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before { HTTPI::expects(:post).returns(new_response(:code => 500)) }

    it "raises a Savon::HTTP::Error" do
      expect { client.request :authenticate }.to raise_error(Savon::HTTP::Error)
    end
  end

  def new_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end

end
