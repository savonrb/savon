require 'spec_helper'

describe Wasabi do
  context 'with: jira.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:jira).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'JiraSoapServiceService' => {
          :ports => {
            'jirasoapservice-v2' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'https://jira.atlassian.com/rpc/soap/jirasoapservice-v2'
            }
          }
        }
      )
    end

    it 'knows the operations' do
      service, port = 'JiraSoapServiceService', 'jirasoapservice-v2'
      operation = wsdl.operation(service, port, 'updateGroup')

      expect(operation.soap_action).to eq('')
      expect(operation.endpoint).to eq('https://jira.atlassian.com/rpc/soap/jirasoapservice-v2')

      expect(operation.input.count).to eq(2)

      namespace = 'http://beans.soap.rpc.jira.atlassian.com'

      expect(operation.input[0].to_a).to eq([
        [['in0'],          { namespace: nil,       form: 'unqualified', singular: true, type: 'xsd:string' }]
      ])

      expect(operation.input[1].to_a).to eq([
        [['in1'],          { namespace: nil,       form: 'unqualified', singular: true }],
        [['in1', 'name'],  { namespace: namespace, form: 'unqualified', singular: true, type: 'xsd:string' }],
        [['in1', 'users'], { namespace: namespace, form: 'unqualified', singular: true }]
      ])
    end

  end
end
