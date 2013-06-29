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

  it 'raises an error because RPC/encoded operations are not ' do
    service, port = 'JiraSoapServiceService', 'jirasoapservice-v2'

    expect { client.operation(service, port, 'updateGroup') }.
      to raise_error(Savon::UnsupportedStyleError, /"updateGroup" is an "rpc\/encoded" style operation/)
  end

end
