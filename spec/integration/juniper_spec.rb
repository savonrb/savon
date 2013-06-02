require "spec_helper"

describe 'Integration with Juniper' do

  subject(:client) { Savon.new fixture('wsdl/juniper') }

  it 'skips the relative schema import to still show other information' do
    expect(client.services).to eq(
      'SystemService' => {
        :ports => {
          'System'   => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
            :location => 'https://10.1.1.1:8443/axis2/services/SystemService'
          }
        }
      }
    )
  end

end
