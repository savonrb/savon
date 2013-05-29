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

      # notice how this contains 9 parts with one element each.
      # it does not include the rpc wrapper.

      input = operation.input.map(&:to_a)
      expect(input).to eq([
        # one part
        [
          # one element
          [['sender'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }]
        ],
        [ [['cellular'],    { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }] ],
        [ [['msg'],         { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }] ],
        [ [['smsnumgroup'], { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }] ],
        [ [['emailaddr'],   { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }] ],
        [ [['udh'],         { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }] ],
        [ [['datetime'],    { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }] ],
        [ [['format'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }] ],
        [ [['dlrurl'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }] ]
      ])
    end

  end
end

