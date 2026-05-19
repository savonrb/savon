# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"

RSpec.describe Savon::Client do
  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  describe ".new" do
    it "supports a block without arguments to create a client with global options" do
      client = Savon.client do
        wsdl Fixture.wsdl(:authentication)
      end

      expect(client.globals[:wsdl]).to eq(Fixture.wsdl(:authentication))
    end

    it "supports a block with one argument to create a client with global options" do
      client = Savon.client do |globals|
        globals.wsdl Fixture.wsdl(:authentication)
      end

      expect(client.globals[:wsdl]).to eq(Fixture.wsdl(:authentication))
    end

    it "builds an HTTPI request for Wasabi via Transport::HTTPI" do
      http_request = mock
      transport    = mock(:wsdl_request => http_request)
      Savon::Transport::HTTPI.expects(:new).with(instance_of(Savon::GlobalOptions)).returns(transport)

      Wasabi::Document.any_instance.expects(:request=).with(http_request)
      Savon.client(:wsdl => "http://example.com")
    end

    it "raises if initialized with anything other than a Hash" do
      expect { Savon.client("http://example.com") }
        .to raise_error(Savon::InitializationError, %r{Some code tries to initialize Savon with the "http://example\.com" \(String\)})
    end

    it "raises if not initialized with either a :wsdl or both :endpoint and :namespace options" do
      expect { Savon.client(:endpoint => "http://example.com") }
        .to raise_error(Savon::InitializationError, /Expected either a WSDL document or the SOAP endpoint and target namespace options/)
    end

    it "raises a when given an unknown option via the Hash syntax" do
      expect { Savon.client(:invalid_global_option => true) }
        .to raise_error(Savon::UnknownOptionError, "Unknown global option: :invalid_global_option")
    end

    it "raises a when given an unknown option via the block syntax" do
      expect { Savon.client { another_invalid_global_option true } }
        .to raise_error(Savon::UnknownOptionError, "Unknown global option: :another_invalid_global_option")
    end
  end

  describe ".new with transport: :faraday" do
    it "passes the Faraday::Connection to Wasabi" do
      Wasabi::Document.any_instance.expects(:request=).with(instance_of(Faraday::Connection))
      new_client_without_wsdl(:transport => :faraday)
    end

    it "does not raise when faraday is available and no incompatible globals are set" do
      expect { new_client_without_wsdl(:transport => :faraday) }.not_to raise_error
    end

    it "raises if the faraday gem is not installed" do
      Savon::GlobalOptions.any_instance.stubs(:faraday_loaded?).returns(false)
      expect { new_client_without_wsdl(:transport => :faraday) }
        .to raise_error(Savon::InitializationError, /transport: :faraday requires the faraday gem.*Add to your Gemfile/m)
    end

    it "raises for incompatible global open_timeout listing the Faraday equivalent" do
      expect { new_client_without_wsdl(:transport => :faraday, :open_timeout => 10) }
        .to raise_error(Savon::InitializationError,
                        /not supported with transport: :faraday.*open_timeout.*client\.faraday\.options\.timeout/m)
    end

    it "raises for incompatible global proxy listing the Faraday equivalent" do
      expect { new_client_without_wsdl(:transport => :faraday, :proxy => "http://proxy:8080") }
        .to raise_error(Savon::InitializationError,
                        /not supported with transport: :faraday.*proxy.*client\.faraday\.proxy/m)
    end

    it "lists all incompatible globals in a single error" do
      expect {
        new_client_without_wsdl(:transport => :faraday, :open_timeout => 10, :proxy => "http://proxy:8080")
      }.to raise_error(Savon::InitializationError) do |error|
        expect(error.message).to include("open_timeout")
        expect(error.message).to include("proxy")
        expect(error.message).to include("client.faraday.options.timeout")
        expect(error.message).to include("client.faraday.proxy")
      end
    end

    it "does not raise when adapter is nil (the default)" do
      expect { new_client_without_wsdl(:transport => :faraday, :adapter => nil) }
        .not_to raise_error
    end

    it "raises when adapter is set to a non-nil value with a solution hint" do
      expect { new_client_without_wsdl(:transport => :faraday, :adapter => :httpclient) }
        .to raise_error(Savon::InitializationError,
                        /not supported with transport: :faraday.*adapter.*client\.faraday\.adapter/m)
    end

    it "does not raise when follow_redirects is false (the default)" do
      expect { new_client_without_wsdl(:transport => :faraday, :follow_redirects => false) }
        .not_to raise_error
    end

    it "raises when follow_redirects is true with a solution hint" do
      expect { new_client_without_wsdl(:transport => :faraday, :follow_redirects => true) }
        .to raise_error(Savon::InitializationError,
                        /not supported with transport: :faraday.*follow_redirects.*client\.faraday\.use/m)
    end
  end

  describe "#faraday" do
    it "returns a Faraday::Connection when transport is :faraday" do
      client = new_client_without_wsdl(:transport => :faraday)
      expect(client.faraday).to be_a(Faraday::Connection)
    end

    it "returns the same connection on repeated calls (memoized)" do
      client = new_client_without_wsdl(:transport => :faraday)
      faraday = client.faraday
      expect(faraday).to be(client.faraday)
    end

    it "raises when transport is not :faraday" do
      expect { new_client.faraday }
        .to raise_error(ArgumentError, /client\.faraday is only available when transport: :faraday is set/)
    end
  end

  describe "#globals" do
    it "returns the current set of global options" do
      expect(new_client.globals).to be_an_instance_of(Savon::GlobalOptions)
    end

    it "defaults :log to false" do
      client = Savon.client(:wsdl => Fixture.wsdl(:authentication))
      expect(client.globals[:log]).to be_falsey
    end

    it "defaults :transport to :httpi" do
      expect(new_client.globals[:transport]).to eq(:httpi)
    end
  end

  describe "#service_name" do
    it "returns the name of the service" do
      expect(new_client.service_name).to eq('AuthenticationWebServiceImplService')
    end
  end

  describe "#operations" do
    it "returns all operation names" do
      operations = new_client.operations
      expect(operations).to eq([:authenticate])
    end

    it "raises when there is no WSDL document" do
      expect { new_client_without_wsdl.operations }.to raise_error("Unable to inspect the service without a WSDL document.")
    end
  end

  describe "#operation" do
    it "returns a new SOAP operation" do
      operation = new_client.operation(:authenticate)
      expect(operation).to be_a(Savon::Operation)
    end

    it "raises if there's no such SOAP operation" do
      expect { new_client.operation(:does_not_exist) }
        .to raise_error(Savon::UnknownOperationError)
    end

    it "does not raise when there is no WSDL document" do
      new_client_without_wsdl.operation(:does_not_exist)
    end
  end

  describe "#call" do
    it "calls a new SOAP operation" do
      locals = { :message => { :symbol => "AAPL" } }
      soap_response = new_soap_response

      wsdl = Wasabi::Document.new('http://example.com')
      globals = Savon::GlobalOptions.new
      operation = Savon::Operation.new(:authenticate, wsdl, globals, Savon::Transport::HTTPI.new(globals))
      operation.expects(:call).with(locals).returns(soap_response)

      Savon::Operation.expects(:create).with(
        :authenticate,
        instance_of(Wasabi::Document),
        instance_of(Savon::GlobalOptions),
        instance_of(Savon::Transport::HTTPI)
      ).returns(operation)

      response = new_client.call(:authenticate, locals)
      expect(response).to eq(soap_response)
    end

    it "supports a block without arguments to call an operation with local options" do
      client = new_client(:endpoint => @server.url(:repeat))

      response = client.call(:authenticate) do
        message(:symbol => "AAPL")
      end

      expect(response.http.body).to include("<symbol>AAPL</symbol>")
    end

    it "supports a block with one argument to call an operation with local options" do
      client = new_client(:endpoint => @server.url(:repeat))

      # supports instance variables!
      @instance_variable = { :symbol => "AAPL" }

      response = client.call(:authenticate) do |locals|
        locals.message(@instance_variable)
      end

      expect(response.http.body).to include("<symbol>AAPL</symbol>")
    end

    it "accepts arguments for the message tag" do
      client   = new_client(:endpoint => @server.url(:repeat))
      response = client.call(:authenticate, :attributes => { "ID" => "ABC321" })

      expect(response.http.body).to include('<tns:authenticate ID="ABC321">')
    end

    it "raises when the operation name is not a symbol" do
      expect { new_client.call("not a symbol") }.to raise_error(
        ArgumentError,
        "Expected the first parameter (the name of the operation to call) to be a symbol\n" \
        "Actual: \"not a symbol\" (String)"
      )
    end

    it "raises a when given an unknown option via the Hash syntax" do
      expect { new_client.call(:authenticate, :invalid_local_option => true) }
        .to raise_error(Savon::UnknownOptionError, "Unknown local option: :invalid_local_option")
    end

    it "raises a when given an unknown option via the block syntax" do
      expect { new_client.call(:authenticate) { another_invalid_local_option true } }
        .to raise_error(Savon::UnknownOptionError, "Unknown local option: :another_invalid_local_option")
    end
  end

  describe "#build_request" do
    it "returns the request without making an actual call" do
      expected_request = mock('request')
      wsdl = Wasabi::Document.new('http://example.com')

      globals = Savon::GlobalOptions.new
      operation = Savon::Operation.new(
        :authenticate,
        wsdl,
        globals,
        Savon::Transport::HTTPI.new(globals)
      )
      operation.expects(:request).returns(expected_request)

      Savon::Operation.expects(:create).with(
        :authenticate,
        instance_of(Wasabi::Document),
        instance_of(Savon::GlobalOptions),
        instance_of(Savon::Transport::HTTPI)
      ).returns(operation)

      operation.expects(:call).never

      client = new_client(:endpoint => @server.url(:repeat))
      request = client.build_request(:authenticate) do
        message(:symbol => "AAPL")
      end

      expect(request).to eq expected_request
    end

    it "accepts a block without arguments" do
      client = new_client(:endpoint => @server.url(:repeat))
      request = client.build_request(:authenticate) do
        message(:symbol => "AAPL")
      end

      expect(request.body)
        .to include('<tns:authenticate><symbol>AAPL</symbol></tns:authenticate>')
    end

    it "accepts a block with one argument" do
      client = new_client(:endpoint => @server.url(:repeat))

      # supports instance variables!
      @instance_variable = { :symbol => "AAPL" }

      request = client.build_request(:authenticate) do |locals|
        locals.message(@instance_variable)
      end

      expect(request.body)
        .to include("<tns:authenticate><symbol>AAPL</symbol></tns:authenticate>")
    end

    it "accepts argument for the message tag" do
      client = new_client(:endpoint => @server.url(:repeat))
      request = client.build_request(:authenticate, :attributes => { "ID" => "ABC321" })

      expect(request.body)
        .to include("<tns:authenticate ID=\"ABC321\"></tns:authenticate>")
    end

    it "raises when the operation name is not a symbol" do
      expect { new_client.build_request("not a symbol") }.to raise_error ArgumentError
    end

    it "raises when given an unknown option via the Hash syntax" do
      expect { new_client.build_request(:authenticate, :invalid_local_option => true) }.to raise_error Savon::UnknownOptionError
    end

    it "raises when given an unknown option via the block syntax" do
      expect { new_client.build_request(:authenticate) { another_invalid_local_option true } }.to raise_error Savon::UnknownOptionError
    end

    it "raises ArgumentError when transport is :faraday" do
      client = new_client_without_wsdl(:transport => :faraday)
      expect { client.build_request(:authenticate) }
        .to raise_error(ArgumentError, /#request.*not supported.*transport: :faraday/m)
    end
  end

  def new_http_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end

  def new_soap_response(options = {})
    http = new_http_response(options)
    globals = Savon::GlobalOptions.new
    locals = Savon::LocalOptions.new

    Savon::Response.new(http, globals, locals)
  end

  def new_client(globals = {})
    globals = { :wsdl => Fixture.wsdl(:authentication), :log => false }.merge(globals)
    Savon.client(globals)
  end

  def new_client_without_wsdl(globals = {})
    globals = { :endpoint => "http://example.co", :namespace => "http://v1.example.com", :log => false }.merge(globals)
    Savon.client(globals)
  end
end
