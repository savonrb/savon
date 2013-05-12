require 'spec_helper'

describe Wasabi do
  context 'with: bookt.wsdl' do

    subject(:wsdl)  { Wasabi.new(wsdl_url) }

    let(:wsdl_url)  { 'http://connect.bookt.com/svc/connect.svc?wsdl' }
    let(:wsdl2_url) { 'http://connect.bookt.com/svc/connect.svc?wsdl=wsdl1' }
    let(:wsdl3_url) { 'http://connect.bookt.com/svc/connect.svc?wsdl=wsdl0' }

    before do
      mock_request wsdl_url,  :bookt
      mock_request wsdl2_url, :bookt2
      mock_request wsdl3_url, :bookt3
    end

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'Connect'       => {
          :ports        => {
            'IConnect'  => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'http://connect.bookt.com/svc/connect.svc'
            }
          }
        }
      )
    end

    it 'resolves WSDL imports to get the operations' do
      operations = wsdl.operations('Connect', 'IConnect')
      expect(operations.count).to eq(26)
    end

  end
end

