require 'spec_helper'

describe 'Integration with IWS' do

  subject(:client) { Savon.new fixture('wsdl/iws') }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'IWSIntegERPservice' => {
        ports: {
          'IWSIntegERPPort' => {
            type:     'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'http://177.75.152.221:8084/WSIntegERP/WSIntegERP.exe/soap/IWSIntegERP'
          }
        }
      }
    )
  end

  it 'raises an error because RPC/encoded operations are not ' do
    service, port = 'IWSIntegERPservice', 'IWSIntegERPPort'
    
    expect { client.operation(service, port, 'Autenticacao') }.
      to raise_error(Savon::UnsupportedStyleError, /"Autenticacao" is an "rpc\/encoded" style operation/)
  end

end
