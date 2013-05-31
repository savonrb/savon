require 'spec_helper'

describe 'Integration with Interhome' do

  subject(:client) { Savon.new fixture('wsdl/interhome') }

  let(:service) { :WebService }
  let(:port)    { :WebServiceSoap }

  it 'skips optional elements in the request' do
    operation = client.operation(service, port, :Availability)

    expect(operation.example_request).to eq(
      Availability: {

        # Notice that these are optional.
        inputValue: {
          AccommodationCode: 'string',
          CheckIn: 'string',
          CheckOut: 'string'
        }

      }
    )

    expect(
      Nokogiri.XML operation.build(
        message: {
          Availability: {
            inputValue: {

              # We're leaving out two elements on purpose.
              AccommodationCode: 'secret'

            }
          }
        }
      )
    ).to be_equivalent_to(
      Nokogiri.XML('
        <env:Envelope
            xmlns:lol0="http://www.interhome.com/webservice"
            xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Header/>
          <env:Body>
            <lol0:Availability>
              <lol0:inputValue>
                <lol0:AccommodationCode>secret</lol0:AccommodationCode>
              </lol0:inputValue>
            </lol0:Availability>
          </env:Body>
        </env:Envelope>
      ')
    ).respecting_element_order
  end

end
