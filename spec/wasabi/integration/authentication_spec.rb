require 'spec_helper'

describe Wasabi do
  context 'with: authentication.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:authentication).read }

    it 'knows the target namespace' do
      expect(wsdl.target_namespace).to eq('http://v1_0.ws.auth.order.example.com/')
    end

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

    it 'knows the operations' do
      service = 'AuthenticationWebServiceImplService'
      port = 'AuthenticationWebServiceImplPort'

      operation = wsdl.operation(service, port, 'authenticate')

      expect(operation.soap_action).to eq('')
      expect(operation.endpoint).to eq('http://example.com/validation/1.0/AuthenticationService')

      expect(operation.input.count).to eq(1)

      namespace = 'http://v1_0.ws.auth.order.example.com/'

      expect(operation.input.first.to_a).to eq([
        [['authenticate'],             { namespace: namespace, form: 'qualified' }],
        [['authenticate', 'user'],     { namespace: namespace, type: 'xs:string', form: 'unqualified' }],
        [['authenticate', 'password'], { namespace: namespace, type: 'xs:string', form: 'unqualified' }]
      ])
    end

  end
end
