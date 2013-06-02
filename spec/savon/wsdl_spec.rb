require 'spec_helper'

describe Savon::WSDL do

  subject(:wsdl) { Savon::WSDL.new fixture('wsdl/authentication'), http_mock }

  let(:operation_name) { 'authenticate' }
  let(:service_name)   { 'AuthenticationWebServiceImplService' }
  let(:port_name)      { 'AuthenticationWebServiceImplPort' }

  describe '#service_name' do
    it 'returns the name of the service' do
      expect(wsdl.service_name).to eq('AuthenticationWebServiceImplService')
    end
  end

  describe '#services' do
    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'AuthenticationWebServiceImplService' => {
          :ports => {
            'AuthenticationWebServiceImplPort' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'http://example.com/validation/1.0/AuthenticationService'
            }
          }
        }
      )
    end
  end

  describe '#operations' do
    it 'returns a Hash of operations' do
      operations = wsdl.operations(service_name, port_name)

      expect(operations.count).to eq(1)
      expect(operations.keys).to eq([operation_name])

      expect(operations[operation_name]).to be_a(Savon::WSDL::Operation)
    end
  end

  describe '#operation' do
    it 'returns a single operation by name' do
      operation = wsdl.operation(service_name, port_name, operation_name)
      expect(operation).to be_a(Savon::WSDL::Operation)
    end
  end

end
