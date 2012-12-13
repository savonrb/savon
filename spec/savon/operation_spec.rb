require "spec_helper"
require "integration/support/server"

describe Savon::Operation do

  let(:globals) { Savon::GlobalOptions.new(:endpoint => @server.url(:repeat), :logger => Savon::NullLogger.new) }
  let(:wsdl)    { Wasabi::Document.new Fixture.wsdl(:authentication) }
  let(:no_wsdl) { Wasabi::Document.new }

  before :all do
    @server = IntegrationServer.run
  end

  after :all do
    @server.stop
  end

  describe ".create with a WSDL" do
    it "returns a new operation" do
      operation = Savon::Operation.create(:authenticate, wsdl, globals)
      expect(operation).to be_a(Savon::Operation)
    end

    it "raises if the operation name is not a Symbol" do
      expect { Savon::Operation.create("not a symbol", wsdl, globals) }.
        to raise_error(ArgumentError, /Expected the first parameter \(the name of the operation to call\) to be a symbol/)
    end

    it "raises if the operation is not available for the service" do
      expect { Savon::Operation.create(:no_such_operation, wsdl, globals) }.
        to raise_error(ArgumentError, /Unable to find SOAP operation: :no_such_operation/)
    end
  end

  describe ".create without a WSDL" do
    it "returns a new operation" do
      operation = Savon::Operation.create(:authenticate, no_wsdl, globals)
      expect(operation).to be_a(Savon::Operation)
    end
  end

  describe "#call" do
    it "returns a response object" do
      expect(new_operation.call).to be_a(Savon::Response)
    end

    it "sets the global :soap_action option from the WSDL" do
      response = new_operation.call
      expect(response.locals[:soap_action]).to eq("authenticate")
    end

    it "sets the global :env_namespace to :env" do
      response = new_operation.call
      expect(response.globals[:env_namespace]).to eq(:env)
    end

    it "does not set the global :env_namespace option if it is already specified" do
      globals[:env_namespace] = :soapenv

      response = new_operation.call
      expect(response.globals[:env_namespace]).to eq(:soapenv)
    end

    it "sets the global :element_form_default option from the WSDL" do
      wsdl.element_form_default = :qualified

      response = new_operation.call
      expect(response.globals[:element_form_default]).to eq(:qualified)
    end

    it "does not set the global :element_form_default option if it is already specified" do
      globals[:element_form_default] = :qualified

      response = new_operation.call
      expect(response.globals[:element_form_default]).to eq(:qualified)
    end

    it "sets the global :namespace_identifier option from the WSDL" do
      response = new_operation.call
      expect(response.globals[:namespace_identifier]).to eq(:tns)
    end

    it "sets the global :namespace_identifier option to :wsdl when there is no WSDL" do
      globals[:namespace] = "http://v1.example.com"

      operation = Savon::Operation.new(:authenticate, no_wsdl, globals)
      response = operation.call

      expect(response.globals[:namespace_identifier]).to eq(:wsdl)
    end

    it "does not set the global :namespace_identifier option if it is already specified" do
      globals[:namespace_identifier] = :v1

      response = new_operation.call
      expect(response.globals[:namespace_identifier]).to eq(:v1)
    end

    it "uses Gyoku to create the local :soap_action option when there is no WSDL" do
      globals[:namespace] = "http://v1.example.com"

      operation = Savon::Operation.new(:authenticate, no_wsdl, globals)
      response = operation.call

      expect(response.locals[:soap_action]).to eq("authenticate")
    end

    it "does not set the local :soap_action option if it is already specified" do
      response = new_operation.call(:soap_action => "urn:authenticate")
      expect(response.locals[:soap_action]).to eq("urn:authenticate")
    end

    it "does not set the local :message_tag option if it is already specified" do
      response = new_operation.call(:message_tag => "doAuthenticate")
      expect(response.locals[:message_tag]).to eq("doAuthenticate")
    end
  end

  def new_operation
    Savon::Operation.create(:authenticate, wsdl, globals)
  end

end
