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

    it 'resolves WSDL imports to get the operations' do
      expect(wsdl.documents.operations.keys).to include('GetCustomer')
    end

  end
end
