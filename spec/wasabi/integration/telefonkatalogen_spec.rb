require 'spec_helper'

describe Wasabi do
  context 'with: telefonkatalogen.wsdl' do

    # reference: savon#295
    subject(:wsdl) { Wasabi.new fixture(:telefonkatalogen).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'SendSms' => {
          :ports => {
            'SendSmsPort' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'http://bedrift.telefonkatalogen.no/tk/websvcsendsms.php'
            }
          }
        }
      )
    end

    it 'knows the operations' do
      operation = wsdl.operation('SendSms', 'SendSmsPort', 'sendsms')

      expect(operation.input).to eq('sendsms')
      expect(operation.soap_action).to eq('sendsms')
      expect(operation.nsid).to eq('tns')
    end

  end
end

