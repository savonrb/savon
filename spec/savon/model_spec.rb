require "spec_helper"
require "integration/support/server"

describe Savon::Model do

  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  describe ".client" do
    it "returns the memoized client" do
      model = Class.new {
        extend Savon::Model
        client :wsdl => Fixture.wsdl(:authentication)
      }

      expect(model.client).to be_a(Savon::Client)
      expect(model.client).to equal(model.client)
    end

    it "raises if the client was not initialized properly" do
      model = Class.new { extend Savon::Model }

      expect { model.client }.
        to raise_error(Savon::InitializationError, /^Expected the model to be initialized/)
    end
  end

  describe ".global" do
    it "sets global options" do
      model = Class.new {
        extend Savon::Model

        client :wsdl => Fixture.wsdl(:authentication)

        global :soap_version, 2
        global :open_timeout, 71
        global :wsse_auth, "luke", "secret", :digest
      }

      expect(model.client.globals[:soap_version]).to eq(2)
      expect(model.client.globals[:open_timeout]).to eq(71)
      expect(model.client.globals[:wsse_auth]).to eq(["luke", "secret", :digest])
    end
  end

  describe ".operations" do
    it "defines class methods for each operation" do
      model = Class.new {
        extend Savon::Model

        client :wsdl => Fixture.wsdl(:authentication)
        operations :authenticate
      }

      expect(model).to respond_to(:authenticate)
    end

    it "executes class-level SOAP operations" do
      repeat_url = @server.url(:repeat)

      model = Class.new {
        extend Savon::Model

        client :endpoint => repeat_url, :namespace => "http://v1.example.com"
        global :log, false

        operations :authenticate
      }

      response = model.authenticate(:xml => Fixture.response(:authentication))
      expect(response.body[:authenticate_response][:return]).to include(:authentication_value)
    end

    it "defines instance methods for each operation" do
      model = Class.new {
        extend Savon::Model

        client :wsdl => Fixture.wsdl(:authentication)
        operations :authenticate
      }

      model_instance = model.new
      expect(model_instance).to respond_to(:authenticate)
    end

    it "executes instance-level SOAP operations" do
      repeat_url = @server.url(:repeat)

      model = Class.new {
        extend Savon::Model

        client :endpoint => repeat_url, :namespace => "http://v1.example.com"
        global :log, false

        operations :authenticate
      }

      model_instance = model.new
      response = model_instance.authenticate(:xml => Fixture.response(:authentication))
      expect(response.body[:authenticate_response][:return]).to include(:authentication_value)
    end
  end

  it "allows to overwrite class operations" do
    repeat_url = @server.url(:repeat)

    model = Class.new {
      extend Savon::Model
      client :endpoint => repeat_url, :namespace => "http://v1.example.com"
    }

    supermodel = model.dup
    supermodel.operations :authenticate

    def supermodel.authenticate(locals = {})
      p "super"
      super
    end

    supermodel.client.expects(:call).with(:authenticate, :message => { :username => "luke", :password => "secret" })
    supermodel.expects(:p).with("super")  # stupid, but works

    supermodel.authenticate(:message => { :username => "luke", :password => "secret" })
  end

  it "allows to overwrite instance operations" do
    repeat_url = @server.url(:repeat)

    model = Class.new {
      extend Savon::Model
      client :endpoint => repeat_url, :namespace => "http://v1.example.com"
    }

    supermodel = model.dup
    supermodel.operations :authenticate
    supermodel = supermodel.new

    def supermodel.authenticate(lcoals = {})
      p "super"
      super
    end

    supermodel.client.expects(:call).with(:authenticate, :message => { :username => "luke", :password => "secret" })
    supermodel.expects(:p).with("super")  # stupid, but works

    supermodel.authenticate(:message => { :username => "luke", :password => "secret" })
  end

end
