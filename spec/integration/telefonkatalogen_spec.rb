require 'spec_helper'

describe 'Integration with Telefonkatalogen' do

  # reference: savon#295
  subject(:client) { Savon.new fixture('wsdl/telefonkatalogen') }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
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
    operation = client.operation('SendSms', 'SendSmsPort', 'sendsms')

    expect(operation.soap_action).to eq('sendsms')

    # notice how this contains 9 parts with one element each.
    # it does not include the rpc wrapper.

    expect(operation.input_parts).to eq([
      [['sender'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['cellular'],    { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['msg'],         { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['smsnumgroup'], { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['emailaddr'],   { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['udh'],         { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['datetime'],    { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['format'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['dlrurl'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }]
    ])
  end

end
