require 'spec_helper'

describe Savon do

  subject(:client) { Savon.new(wsdl, http_mock) }

  let(:wsdl) { fixture('wsdl/amazon') }

  let(:service_name)   { 'AmazonFPS' }
  let(:port_name)      { 'AmazonFPSPort' }
  let(:operation_name) { 'Pay' }

  describe '.http_adapter' do
    it 'defines the default HTTP client to use' do
      expect(Savon.http_adapter).to eq(Savon::HTTPClient)
    end
  end

  describe '.new' do
    it 'expects a local or remote WSDL document' do
      Wasabi.expects(:new).with(wsdl, instance_of(Savon.http_adapter)).returns(:wasabi)
      Savon.new(wsdl)
    end

    it 'also accepts a custom HTTP adapter to replace the default' do
      http = :my_http_adapter
      Wasabi.expects(:new).with(wsdl, http).returns(:wasabi)

      Savon.new(wsdl, http)
    end
  end

  describe '#wsdl' do
    it 'returns the Wasabi instance' do
      expect(client.wsdl).to be_an_instance_of(Wasabi)
    end
  end

  describe '#http' do
    it 'returns the HTTP adapter‘s client to configure' do
      client = Savon.new(wsdl)
      expect(client.http).to be_an_instance_of(HTTPClient)
    end
  end

  describe '#services' do
    it 'returns the services and ports defined by the WSDL' do
      expect(client.services).to eq(
        'AmazonFPS' => {
          ports: {
            'AmazonFPSPort' => {
              type:     'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://fps.amazonaws.com'
            }
          }
        }
      )
    end
  end

  describe '#operations' do
    it 'returns an Array of operations for a service and port' do
      operations = client.operations(service_name, port_name)

      expect(operations.count).to eq(25)
      expect(operations).to include('GetAccountBalance', 'GetTransaction', 'SettleDebt')
    end

    it 'also accepts symbols for the service and port name' do
      operations = client.operations(:AmazonFPS, :AmazonFPSPort)
      expect(operations.count).to eq(25)
    end

    it 'raises if the service could not be found' do
      expect { client.operations(:UnknownService, :UnknownPort) }.
        to raise_error(ArgumentError, 'Unknown service "UnknownService"')
    end

    it 'raises if the port could not be found' do
      expect { client.operations(service_name, :UnknownPort) }.
        to raise_error(ArgumentError, 'Unknown port "UnknownPort" for service "AmazonFPS"')
    end
  end

  describe '#operation' do
    it 'returns an Operation by service, port and operation name' do
      operation = client.operation(service_name, port_name, operation_name)
      expect(operation).to be_a(Savon::Operation)
    end

    it 'also accepts symbols for the service, port and operation name' do
      operation = client.operation(:AmazonFPS, :AmazonFPSPort, :Pay)
      expect(operation).to be_a(Savon::Operation)
    end

    it 'raises if the service could not be found' do
      expect { client.operation(:UnknownService, :UnknownPort, :UnknownOperation) }.
        to raise_error(ArgumentError, 'Unknown service "UnknownService"')
    end

    it 'raises if the port could not be found' do
      expect { client.operation(service_name, :UnknownPort, :UnknownOperation) }.
        to raise_error(ArgumentError, 'Unknown port "UnknownPort" for service "AmazonFPS"')
    end

    it 'raises if the operation could not be found' do
      expect { client.operation(service_name, port_name, :UnknownOperation) }.
        to raise_error(ArgumentError, 'Unknown operation "UnknownOperation" for service "AmazonFPS" and port "AmazonFPSPort"')
    end
  end

  describe '#call' do
    it 'calls an Operation by service, port and operation name plus options' do
      http_mock.fake_request('https://fps.amazonaws.com')

      options = {
        message: {
          Pay: { SenderTokenId: 1, RecipientTokenId: 2 }
        }
      }

      response = client.call(service_name, port_name, operation_name, options)
      expect(response).to be_a(Savon::Response)
    end

  end

end
