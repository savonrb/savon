 require 'spec_helper'

describe 'Integration with temperature.xml' do

  subject(:client) { Savon.new fixture('wsdl/temperature') }

  let(:service) { :ConvertTemperature }
  let(:port)    { :ConvertTemperatureSoap12 }

  it 'converts 30 degrees celsius to 86 degrees fahrenheit' do
    operation = client.operation(service, port, :ConvertTemp)

    # Check the example request.
    expect(operation.example_request).to eq(
      ConvertTemp: {
        Temperature: 'double',
        FromUnit: 'string',
        ToUnit: 'string'
      }
    )

    # Actual message to send.
    # For the corrent values to pass for :from_unit and :to_unit, I searched the WSDL for
    # the 'FromUnit' type which is a 'TemperatureUnit' enumeration that looks like this:
    #
    # <s:simpleType name='TemperatureUnit'>
    #   <s:restriction base='s:string'>
    #     <s:enumeration value='degreeCelsius'/>
    #     <s:enumeration value='degreeFahrenheit'/>
    #     <s:enumeration value='degreeRankine'/>
    #     <s:enumeration value='degreeReaumur'/>
    #     <s:enumeration value='kelvin'/>
    #   </s:restriction>
    # </s:simpleType>
    #
    # TODO: somehow expose the enumeration options through the example request.
    message = {
      ConvertTemp: {
        Temperature: 30,
        FromUnit: 'degreeCelsius',
        ToUnit: 'degreeFahrenheit'
      }
    }

    # Build a raw request.
    actual = Nokogiri.XML operation.build(message: message)

    # The expected request.
    expected = Nokogiri.XML(%{
      <env:Envelope
          xmlns:lol0="http://www.webserviceX.NET/"
          xmlns:env="http://www.w3.org/2003/05/soap-envelope">
        <env:Header/>
        <env:Body>
          <lol0:ConvertTemp>
            <lol0:Temperature>30</lol0:Temperature>
            <lol0:FromUnit>degreeCelsius</lol0:FromUnit>
            <lol0:ToUnit>degreeFahrenheit</lol0:ToUnit>
          </lol0:ConvertTemp>
        </env:Body>
      </env:Envelope>
    })

    expect(actual).to be_equivalent_to(expected).respecting_element_order
  end

end
