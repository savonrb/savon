require 'spec_helper'

describe Wasabi do
  context 'with: bydexchange.wsdl' do

    subject(:wsdl)  { Wasabi.new(wsdl_url) }

    let(:wsdl_url)  { 'http://bydexchange.nbs-us.com/BYDExchangeServer.svc?wsdl' }
    let(:wsdl2_url) { 'http://bydexchange.nbs-us.com/BYDExchangeServer.svc?wsdl=wsdl0' }

    before do
      mock_request wsdl_url,  :bydexchange
      mock_request wsdl2_url, :bydexchange2
    end

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'BYDExchangeServer' => {
          :ports => {
            'BasicHttpBinding_IBYDExchangeServer' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'http://bydexchange.nbs-us.com/BYDExchangeServer.svc'
            }
          }
        }
      )
    end

    it 'resolves WSDL imports to get the operations' do
      operations = wsdl.operations('BYDExchangeServer', 'BasicHttpBinding_IBYDExchangeServer')
      expect(operations.keys).to include('GetCustomer')
    end

  end
end
