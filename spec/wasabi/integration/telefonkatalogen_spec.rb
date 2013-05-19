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

      expect(operation.soap_action).to eq('sendsms')

      expect(operation.input.count).to eq(9)

      expect(operation.input.first.nsid).to eq('xsd')

      # contains the message parts, not the rpc wrapper
      input = operation.input
      expect(input.count).to eq(9)


      expect(input[0].name).to eq('sender')
      expect(input[0].nsid).to eq('xsd')
      expect(input[0].local).to eq('string')

      expect(input[1].name).to eq('cellular')
      expect(input[2].name).to eq('msg')
      expect(input[3].name).to eq('smsnumgroup')
      expect(input[4].name).to eq('emailaddr')
      expect(input[5].name).to eq('udh')
      expect(input[6].name).to eq('datetime')
      expect(input[7].name).to eq('format')
      expect(input[8].name).to eq('dlrurl')
    end

  end
end

