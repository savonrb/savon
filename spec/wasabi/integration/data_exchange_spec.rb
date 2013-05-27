require 'spec_helper'

describe Wasabi do
  context 'with: data_exchange.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:data_exchange).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
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

      operation = wsdl.operation(service, port, 'submit')

      expect(operation.soap_action).to eq('')
      expect(operation.endpoint).to eq('http://my.yfu.org/cgi-bin/WebObjects/WebService.woa/ws/DataExchange')

      input = operation.input.map(&:to_a)

      # so, soapUI ignores the third part element since it can't resolve the type,
      # but we're currently listing it, because we're not properly separating between
      # known built-in simple types and unknown types so we can't make that choice.

      expect(input).to eq([
        [[['in0'], { namespace: nil, form: 'unqualified', type: 'soapenc:string'  }]],
        [[['in1'], { namespace: nil, form: 'unqualified', type: 'soapenc:string'  }]],

                                                          # not a built-in type
        [[['in2'], { namespace: nil, form: 'unqualified', type: 'YFUDataExchange' }]]
      ])
    end

  end
end
