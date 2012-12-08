require "spec_helper"

describe Savon::NewClient do

  subject(:client) { Savon.new_client Fixture.wsdl(:authentication) }

  describe "#operations" do
    it "returns all operation names" do
      operations = client.operations
      expect(operations).to eq([:authenticate])
    end
  end

  describe "#operation" do
    it "returns a new SOAP operation" do
      operation = client.operation(:authenticate)
      expect(operation).to be_a(Savon::Operation)
    end

    it "raises if there's no such SOAP operation" do
      expect { client.operation(:does_not_exist) }.
        to raise_error(ArgumentError)
    end
  end

  describe "#call" do
    it "calls a new SOAP operation" do
      options = { :message => { :symbol => "AAPL" } }
      soap_response = new_soap_response

      wsdl = Wasabi::Document.new('http://example.com')
      operation = Savon::Operation.new(:authenticate, wsdl, Savon::Options.new)
      operation.expects(:call).with(options).returns(soap_response)
      Savon::Operation.expects(:create).returns(operation)

      response = client.call(:authenticate, options)
      expect(response).to eq(soap_response)
    end

    it "sets the cookies for the next request" do
      last_response = new_http_response(:headers => { "Set-Cookie" => "some-cookie=choc-chip; Path=/; HttpOnly" })

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
      expect { client.call("not a symbol") }.to raise_error(
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
    config = Savon::Config.default
    response = new_http_response(options)

    Savon::SOAP::Response.new(config, response)
  end

end
