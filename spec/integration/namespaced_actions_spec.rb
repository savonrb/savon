require 'spec_helper'

describe 'Integration with namespaced actions example' do

  subject(:client) { Savon.new fixture('wsdl/namespaced_actions') }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'api' => {
        :ports => {
          'apiSoap'   => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
            :location => 'https://api.example.com/api/api.asmx'
          },
          'apiSoap12' => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap12/',
            :location => 'https://api.example.com/api/api.asmx'
          }
        }
      }
    )
  end

  it 'works fine with dot-namespaced operations' do
    operation = client.operation('api', 'apiSoap', 'DeleteClient')

    expect(operation.soap_action).to eq('http://api.example.com/api/Client.Delete')
    expect(operation.endpoint).to eq('https://api.example.com/api/api.asmx')

    expect(operation.body_parts).to eq([
      [['Client.Delete'],             { namespace: 'http://api.example.com/api/', form: 'qualified', singular: true }],
      [['Client.Delete', 'ApiKey'],   { namespace: 'http://api.example.com/api/', form: 'qualified', singular: true, type: 's:string' }],
      [['Client.Delete', 'ClientID'], { namespace: 'http://api.example.com/api/', form: 'qualified', singular: true, type: 's:string' }]
    ])
  end

end
