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

      wsdl = Wasabi::Document.new('http://example.com')
      operation = Savon::Operation.new(:authenticate, wsdl, Savon::Options.new)
      operation.expects(:call).with(options).returns(:response)
      Savon::Operation.expects(:create).returns(operation)

      response = client.call(:authenticate, options)
      expect(response).to eq(:response)
    end
  end

end
