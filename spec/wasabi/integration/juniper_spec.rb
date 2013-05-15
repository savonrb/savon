require "spec_helper"

describe Wasabi do
  context 'with: juniper.wsdl' do

    subject(:wsdl) { Wasabi.new(xml) }

    let(:xml) { fixture(:juniper).read }

    it 'returns a map of services and ports' do
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

    it 'does not blow up when an extension base element is defined in an import' do
      operation = wsdl.operation('SystemService', 'System', 'GetSystemInfoRequest')

      operation.soap_action.should == 'urn:#GetSystemInfoRequest'

      expect(operation.input.count).to eq(1)
      input = operation.input.first

      expect(input.namespace).to eq('http://juniper.net/webproxy/systemservice')
      expect(input.local).to eq('GetSystemInfoRequest')
    end

  end
end
