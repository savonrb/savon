require 'spec_helper'

describe Wasabi do
  context 'with: crowd.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:crowd).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
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
      operation = wsdl.operation(service, port, 'addAttributeToGroup')

      expect(operation.soap_action).to eq('')
      expect(operation.endpoint).to eq('http://magnesium:8095/crowd/services/SecurityServer')

      expect(operation.input.count).to eq(1)

      ns1 = 'urn:SecurityServer'
      ns2 = 'http://authentication.integration.crowd.atlassian.com'
      ns3 = 'http://soap.integration.crowd.atlassian.com'

      expect(operation.input.first.to_a).to eq([
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
end
