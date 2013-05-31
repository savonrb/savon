require 'spec_helper'

describe Wasabi do
  context 'with: oracle.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:oracle).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to include(
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
      operation = wsdl.operation(service, port, 'joinGroups')

      expect(operation.soap_action).to eq('#joinGroups')
      expect(operation.endpoint).to eq('https://fap0023-bi.oracleads.com/analytics-ws/saw.dll?SoapImpl=securityService')

      expect(operation.input.count).to eq(1)

      namespace = 'urn://oracle.bi.webservices/v7'

      expect(operation.input.first.to_a).to eq([
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
end
