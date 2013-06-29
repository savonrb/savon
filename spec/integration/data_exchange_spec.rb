require 'spec_helper'

describe 'Integration with DataExchange' do

  subject(:client) { Savon.new fixture('wsdl/data_exchange') }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'DataExchange'       => {
        :ports        => {
          'DataExchange'  => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
            :location => 'http://my.yfu.org/cgi-bin/WebObjects/WebService.woa/ws/DataExchange'
          }
        }
      }
    )
  end

  it 'knows the operations' do
    service = port = 'DataExchange'

    operation = client.operation(service, port, 'submit')

    expect(operation.soap_action).to eq('')
    expect(operation.endpoint).to eq('http://my.yfu.org/cgi-bin/WebObjects/WebService.woa/ws/DataExchange')

    # so, soapUI ignores the third part element since it can't resolve the type,
    # but we're currently listing it, because we're not properly separating between
    # known built-in simple types and unknown types so we can't make that choice.

    expect(operation.body_parts).to eq([
      [['in0'], { namespace: nil, form: 'unqualified', type: 'soapenc:string', singular: true }],
      [['in1'], { namespace: nil, form: 'unqualified', type: 'soapenc:string', singular: true }],

                                                        # not a built-in type
      [['in2'], { namespace: nil, form: 'unqualified', type: 'YFUDataExchange', singular: true }]
    ])
  end

end
