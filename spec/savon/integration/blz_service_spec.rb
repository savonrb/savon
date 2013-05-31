 require 'spec_helper'

describe 'Integration with blz_service.xml' do

  subject(:client) { Savon.new fixture('wsdl/blz_service') }

  let(:service) { :BLZService }
  let(:port)    { :BLZServiceSOAP11port_http }

  it 'works just fine' do
    operation = client.operation(service, port, :getBank)

    # Check the example request.
    expect(operation.example_request).to eq(
      getBank: {
        blz: 'string'
      }
    )

    # Build a raw request.
    actual = Nokogiri.XML operation.build(message: { getBank: { blz: 70070010 } })

    # The expected request.
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

    expect(actual).to be_equivalent_to(expected).respecting_element_order
  end

end
