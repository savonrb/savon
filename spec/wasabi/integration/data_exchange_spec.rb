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

      # we're ignoring the third part element which we can't resolve the type for.
      # this seems to be an invalid spec, so we're doing the same as soapUI.
      expect(input.count).to eq(2)

      expect(input[0].name).to eq('in0')
      expect(input[0].nsid).to eq('soapenc')
      expect(input[0].local).to eq('string')

      expect(input[1].name).to eq('in1')
      expect(input[1].nsid).to eq('soapenc')
      expect(input[1].local).to eq('string')
    end

  end
end
