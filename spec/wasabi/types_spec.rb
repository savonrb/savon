require 'spec_helper'

describe Wasabi do

  it 'knows simple types' do
    wsdl = wsdl('
      <xs:schema xmlns="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:ActionWebService">
        <xs:simpleType name="TemperatureUnit">
          <xs:restriction base="xs:string">
            <xs:enumeration value="degreeCelsius" />
            <xs:enumeration value="degreeFahrenheit" />
            <xs:enumeration value="degreeRankine" />
            <xs:enumeration value="degreeReaumur" />
            <xs:enumeration value="kelvin" />
          </xs:restriction>
        </xs:simpleType>
      </xs:schema>
    ')

    unit = wsdl.schemas.first.simple_types['TemperatureUnit']

    expect(unit).to be_a(Wasabi::Type::SimpleType)
    expect(unit.type).to eq('xs:string')
  end

  def wsdl(types)
    wsdl = %'<definitions name="Api" targetNamespace="urn:ActionWebService"
                 xmlns="http://schemas.xmlsoap.org/wsdl/"
                 xmlns:tns="urn:ActionWebService"
                 xmlns:ens="http://api.example.com/"
                 xmlns:ons="http://object.api.example.com/"
                 xmlns:xs="http://www.w3.org/2001/XMLSchema">
               <types>
                 #{types}
               </types>
             </definitions>'

    Wasabi.new(wsdl)
  end

end
