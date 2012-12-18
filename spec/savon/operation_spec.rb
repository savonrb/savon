require "spec_helper"
require "integration/support/server"

describe Savon::Operation do

  let(:globals) { Savon::GlobalOptions.new(:endpoint => @server.url(:repeat), :log => false) }
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
      operation = Savon::Operation.create(:authenticate, wsdl, globals)
      expect(operation.call).to be_a(Savon::Response)
    end
  end

end
