require 'spec_helper'

describe 'Integration with Oracle' do

  subject(:client) { Savon.new fixture('wsdl/oracle') }

  it 'returns a map of services and ports' do
    expect(client.services).to include(
      'SAWSessionService' => {
        ports: {
          'SAWSessionServiceSoap' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'https://fap0023-bi.oracleads.com/analytics-ws/saw.dll?SoapImpl=nQSessionService'
          }
        }
      },
      'WebCatalogService' => {
        ports: {
          'WebCatalogServiceSoap' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'https://fap0023-bi.oracleads.com/analytics-ws/saw.dll?SoapImpl=webCatalogService'
          }
        }
      },
      'XmlViewService' => {
        ports: {
          'XmlViewServiceSoap' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'https://fap0023-bi.oracleads.com/analytics-ws/saw.dll?SoapImpl=xmlViewService'
          }
        }
      }
    )
  end

  it 'knows the operations' do
    service, port = 'SecurityService', 'SecurityServiceSoap'
    operation = client.operation(service, port, 'joinGroups')

    expect(operation.soap_action).to eq('#joinGroups')
    expect(operation.endpoint).to eq('https://fap0023-bi.oracleads.com/analytics-ws/saw.dll?SoapImpl=securityService')

    namespace = 'urn://oracle.bi.webservices/v7'

    expect(operation.body_parts).to eq([
      [['joinGroups'],                          { namespace: namespace, form: 'qualified', singular: true  }],
      [['joinGroups', 'group'],                 { namespace: namespace, form: 'qualified', singular: false }],
      [['joinGroups', 'group', 'name'],         { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['joinGroups', 'group', 'accountType'],  { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:int'    }],
      [['joinGroups', 'group', 'guid'],         { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['joinGroups', 'group', 'displayName'],  { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['joinGroups', 'member'],                { namespace: namespace, form: 'qualified', singular: false }],
      [['joinGroups', 'member', 'name'],        { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['joinGroups', 'member', 'accountType'], { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:int'    }],
      [['joinGroups', 'member', 'guid'],        { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['joinGroups', 'member', 'displayName'], { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['joinGroups', 'sessionID'],             { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }]
    ])
  end

end
