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

  it 'raises an error because RPC/encoded operations are not ' do
    service = port = 'DataExchange'

    expect { client.operation(service, port, 'submit') }.
      to raise_error(Savon::UnsupportedStyleError, /"submit" is an "rpc\/encoded" style operation/)
  end

end
