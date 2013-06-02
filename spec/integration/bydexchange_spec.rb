require 'spec_helper'

describe 'Integration with BYDExchange' do

  subject(:client) { Savon.new(wsdl_url, http_mock) }

  let(:wsdl_url)  { 'http://bydexchange.nbs-us.com/BYDExchangeServer.svc?wsdl' }
  let(:wsdl2_url) { 'http://bydexchange.nbs-us.com/BYDExchangeServer.svc?wsdl=wsdl0' }

  before do
    http_mock.fake_request(wsdl_url, 'wsdl/bydexchange/bydexchange.wsdl')
    http_mock.fake_request(wsdl2_url, 'wsdl/bydexchange/bydexchange2.wsdl')

    # 8 schemas to import
    schema_import_base = 'http://bydexchange.nbs-us.com/BYDExchangeServer.svc?xsd=xsd%d'
    (0..8).each do |i|
      url = schema_import_base % i
      http_mock.fake_request(url, "wsdl/bydexchange/bydexchange#{i}.xsd")
    end
  end

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
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
    operations = client.operations('BYDExchangeServer', 'BasicHttpBinding_IBYDExchangeServer')
    expect(operations).to include('GetCustomer')
  end

end
