require "spec_helper"

describe Savon::NewClient do

  describe ".new" do
    it "raises if not initialized with either a :wsdl or both :endpoint and :namespace options" do
      expect { Savon.new_client(:endpoint => "http://example.com") }.
        to raise_error(ArgumentError, /Expected either a WSDL document or the SOAP endpoint and target namespace options/)
    end

    it "calls GlobalOptions.new_with_defaults" do
      globals = Savon::GlobalOptions.new(:wsdl => Fixture.wsdl(:authentication))
      Savon::GlobalOptions.expects(:new_with_defaults).returns(globals)

      new_client
    end
  end

  describe "#globals" do
    it "returns the current set of global options" do
      expect(new_client.globals).to be_an_instance_of(Savon::GlobalOptions)
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
      expect { new_client.operation(:does_not_exist) }.
        to raise_error(ArgumentError)
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
      operation = Savon::Operation.new(:authenticate, wsdl, Savon::GlobalOptions.new_with_defaults)
      operation.expects(:call).with(locals).returns(soap_response)
      Savon::Operation.expects(:create).returns(operation)

      response = new_client.call(:authenticate, locals)
      expect(response).to eq(soap_response)
    end

    it "sets the cookies for the next request" do
      last_response = new_http_response(:headers => { "Set-Cookie" => "some-cookie=choc-chip; Path=/; HttpOnly" })
      client = new_client

      HTTPI.stubs(:post).returns(last_response)

      # does not try to set cookies for the first request
      HTTPI::Request.any_instance.expects(:set_cookies).never
      client.call(:authenticate)

      HTTPI.stubs(:post).returns(new_http_response)

      # sets cookies from the last response
      HTTPI::Request.any_instance.expects(:set_cookies).with(last_response)
      client.call(:authenticate)
    end

    it "raises when the operation name is not a symbol" do
      expect { new_client.call("not a symbol") }.to raise_error(
        ArgumentError,
        "Expected the first parameter (the name of the operation to call) to be a symbol\n" \
        "Actual: \"not a symbol\" (String)"
      )
    end
  end

  def new_http_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end

  def new_soap_response(options = {})
    http = new_http_response(options)
    globals = Savon::GlobalOptions.new_with_defaults
    locals = Savon::LocalOptions.new

    Savon::Response.new(http, globals, locals)
  end

  def new_client(globals = {})
    globals = { :wsdl => Fixture.wsdl(:authentication), :logger => Savon::NullLogger.new }.merge(globals)
    Savon.new_client(globals)
  end

  def new_client_without_wsdl(globals = {})
    globals = { :endpoint => "http://example.co", :namespace => "http://v1.example.com", :logger => Savon::NullLogger.new }.merge(globals)
    Savon.new_client(globals)
  end

end