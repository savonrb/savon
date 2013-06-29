 require 'spec_helper'

describe 'Integration with BLZService' do

  subject(:client) { Savon.new fixture('wsdl/blz_service') }

  let(:service_name) { :BLZService }
  let(:port_name)    { :BLZServiceSOAP11port_http }

  it 'creates an example request' do
    operation = client.operation(service_name, port_name, :getBank)

    expect(operation.example_body).to eq(
      getBank: {
        blz: 'string'
      }
    )
  end

  it 'builds a request' do
    operation = client.operation(service_name, port_name, :getBank)

    operation.body = {
      getBank: {
        blz: 70070010
      }
    }

    expected = Nokogiri.XML(%{
      <env:Envelope
          xmlns:lol0="http://thomas-bayer.com/blz/"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header/>
        <env:Body>
          <lol0:getBank>
            <lol0:blz>70070010</lol0:blz>
          </lol0:getBank>
        </env:Body>
      </env:Envelope>
    })

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
