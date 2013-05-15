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

      input = operation.input

      expect(input[0].nsid).to be_nil
      expect(input[0].local).to eq('in0')

      expect(input[1].nsid).to be_nil
      expect(input[1].local).to eq('in1')

      # notice that soapUI ignore this part!
      # probably because it can't find the type definition.
      expect(input[2].nsid).to be_nil
      expect(input[2].local).to eq('in2')
    end

  end
end
