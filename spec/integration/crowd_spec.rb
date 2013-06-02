require 'spec_helper'

describe 'Integration with Atlassian Crowd' do

  subject(:client) { Savon.new fixture('wsdl/crowd') }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'SecurityServer' => {
        :ports => {
          'SecurityServerHttpPort' => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
            :location => 'http://magnesium:8095/crowd/services/SecurityServer'
          }
        }
      }
    )
  end

  it 'knows the operations' do
    service, port = 'SecurityServer', 'SecurityServerHttpPort'
    operation = client.operation(service, port, 'addAttributeToGroup')

    expect(operation.soap_action).to eq('')
    expect(operation.endpoint).to eq('http://magnesium:8095/crowd/services/SecurityServer')

    ns1 = 'urn:SecurityServer'
    ns2 = 'http://authentication.integration.crowd.atlassian.com'
    ns3 = 'http://soap.integration.crowd.atlassian.com'

    expect(operation.input_parts).to eq([
      [['addAttributeToGroup'],                            { namespace: ns1, form: 'qualified', singular: true }],
      [['addAttributeToGroup', 'in0'],                     { namespace: ns1, form: 'qualified', singular: true }],
      [['addAttributeToGroup', 'in0', 'name'],             { namespace: ns2, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['addAttributeToGroup', 'in0', 'token'],            { namespace: ns2, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['addAttributeToGroup', 'in1'],                     { namespace: ns1, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['addAttributeToGroup', 'in2'],                     { namespace: ns1, form: 'qualified', singular: true }],
      [['addAttributeToGroup', 'in2', 'name'],             { namespace: ns3, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['addAttributeToGroup', 'in2', 'values'],           { namespace: ns3, form: 'qualified', singular: true }],
      [['addAttributeToGroup', 'in2', 'values', 'string'], { namespace: ns1, form: 'qualified', singular: false, type: 'xsd:string' }]
    ])
  end

end
