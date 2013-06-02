require 'spec_helper'

describe 'Integration with Authentication service' do

  subject(:client) { Savon.new fixture('wsdl/authentication') }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
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

    operation = client.operation(service, port, 'authenticate')

    expect(operation.soap_action).to eq('')
    expect(operation.endpoint).to eq('http://example.com/validation/1.0/AuthenticationService')

    namespace = 'http://v1_0.ws.auth.order.example.com/'

    expect(operation.input_parts).to eq([
      [['authenticate'],             { namespace: namespace, form: 'qualified', singular: true }],
      [['authenticate', 'user'],     { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['authenticate', 'password'], { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }]
    ])
  end

end
