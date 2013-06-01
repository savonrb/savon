 require 'spec_helper'

describe 'Integration with RATP' do

  subject(:client) { Savon.new fixture('wsdl/ratp') }

  let(:service_name) { :Wsiv }
  let(:port_name)    { :WsivSOAP11port_http }

  it 'builds a request' do
    operation = client.operation(service_name, port_name, :getStations)

    request = Nokogiri.XML operation.build(
      message: {
        getStations: {
          station: {
            id: 1975
          },
          limit: 1
        }
      }
    )

    # The expected request.
    expected = Nokogiri.XML(%{
      <env:Envelope
          xmlns:lol0="http://wsiv.ratp.fr"
          xmlns:lol1="http://wsiv.ratp.fr/xsd"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header/>
        <env:Body>
          <lol0:getStations>
            <lol0:station>
              <lol1:id>1975</lol1:id>
            </lol0:station>
            <lol0:limit>1</lol0:limit>
          </lol0:getStations>
        </env:Body>
      </env:Envelope>
    })

    expect(request).to be_equivalent_to(expected).respecting_element_order
  end

end
