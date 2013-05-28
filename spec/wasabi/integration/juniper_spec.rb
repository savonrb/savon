require "spec_helper"

describe Wasabi do
  context 'with: juniper.wsdl' do

    subject(:wsdl) { Wasabi.new(xml) }

    let(:xml) { fixture('juniper.wsdl').read }

    it 'skips the relative schema import to still show other information' do
      expect(wsdl.services).to eq(
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
end
