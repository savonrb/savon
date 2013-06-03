require 'spec_helper'

describe 'Integration with Atlassian Jira' do

  subject(:client) { Savon.new fixture('wsdl/jira') }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
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
    operation = client.operation(service, port, 'updateGroup')

    expect(operation.soap_action).to eq('')
    expect(operation.endpoint).to eq('https://jira.atlassian.com/rpc/soap/jirasoapservice-v2')

    namespace = 'http://beans.soap.rpc.jira.atlassian.com'

    expect(operation.body_parts).to eq([
      [['in0'],          { namespace: nil,       form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['in1'],          { namespace: nil,       form: 'unqualified', singular: true }],
      [['in1', 'name'],  { namespace: namespace, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['in1', 'users'], { namespace: namespace, form: 'unqualified', singular: true }]
    ])
  end

end
