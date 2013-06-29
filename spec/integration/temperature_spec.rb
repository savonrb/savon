 require 'spec_helper'

describe 'Integration with Temperature service' do

  subject(:client) { Savon.new fixture('wsdl/temperature') }

  let(:service_name) { :ConvertTemperature }
  let(:port_name)    { :ConvertTemperatureSoap12 }

  it 'returns an empty Hash if there are no header parts' do
    operation = client.operation(service_name, port_name, :ConvertTemp)
    expect(operation.example_header).to eq({})
  end

  it 'creates an example body' do
    operation = client.operation(service_name, port_name, :ConvertTemp)

    expect(operation.example_body).to eq(
      ConvertTemp: {
        Temperature: 'double',
        FromUnit: 'string',
        ToUnit: 'string'
      }
    )
  end

  it 'builds a request' do
    operation = client.operation(service_name, port_name, :ConvertTemp)

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
    operation.body = {
      ConvertTemp: {
        Temperature: 30,
        FromUnit: 'degreeCelsius',
        ToUnit: 'degreeFahrenheit'
      }
    }

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

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
